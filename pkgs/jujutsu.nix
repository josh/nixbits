{
  lib,
  symlinkJoin,
  makeWrapper,
  runCommand,
  testers,
  writeText,
  git,
  jujutsu,
  watchman,
  nixbits,
  git-config ? nixbits.git-config,
  jujutsu-config ? nixbits.jujutsu-config,
}:
let
  jujutsu' = symlinkJoin {
    pname = "jujutsu";
    inherit (jujutsu) version;

    paths = [
      jujutsu
      nixbits.jujutsu-bookmark-clean
      nixbits.jujutsu-clone
      nixbits.jujutsu-git-set-upstream
      (nixbits.jujutsu-init.override {
        inherit git-config jujutsu-config;
      })
      nixbits.jujutsu-new-main
      (nixbits.jujutsu-pull.override {
        inherit git-config jujutsu-config;
      })
      nixbits.jujutsu-untracked
      nixbits.jujutsu-wip-changes
    ]
    ++ (lib.lists.optional watchman.meta.available watchman);
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/jj \
        --set JJ_CONFIG ${jujutsu-config} \
        --set GIT_CONFIG_GLOBAL ${git-config}
    '';

    meta = {
      inherit (jujutsu.meta)
        description
        homepage
        license
        platforms
        ;
      mainProgram = "jj";
    };
  };
in
jujutsu'.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        jujutsu = finalAttrs.finalPackage;
      in
      {
        version = testers.testVersion {
          package = jujutsu;
          command = "jj version";
          inherit (jujutsu) version;
        };

        author = runCommand "test-jj-author" { nativeBuildInputs = [ jujutsu ]; } ''
          expected="Joshua Peek"
          actual="$(jj config get user.name)"
          if [[ "$actual" != "$expected" ]]; then
            echo "expected, '$expected' but was '$actual'"
            return 1
          fi
          touch $out
        '';

        config-override =
          runCommand "test-jj-config-override"
            {
              nativeBuildInputs = [
                (nixbits.jujutsu.override {
                  jujutsu-config = writeText "jj-override.toml" ''
                    [user]
                    name = "Override Author"
                    email = "override@example.com"
                  '';
                })
              ];
            }
            ''
              test "$(jj config get user.name)" = "Override Author"
              test "$(jj config get user.email)" = "override@example.com"
              touch $out
            '';

        init-config-overrides =
          let
            bundle = nixbits.jujutsu.override {
              git-config = writeText "jj-bundle-git-config" ''
                [core]
                excludesFile = ${writeText "jj-bundle-gitignore" "ignored-by-override\n"}
              '';
              jujutsu-config = writeText "jj-bundle-config.toml" ''
                [user]
                name = "Override Author"
                email = "override@example.com"
              '';
            };
          in
          runCommand "test-jj-bundled-init-config-overrides" { nativeBuildInputs = [ git ]; } ''
            export HOME="$PWD/home"
            unset GIT_CONFIG_GLOBAL JJ_CONFIG
            mkdir -p "$HOME" repo
            cd repo
            git init
            touch visible ignored-by-override
            ${bundle}/bin/jj-init
            test "$(${bundle}/bin/jj log --ignore-working-copy --no-graph --revisions @ --template 'author.name()')" = "Override Author"
            test "$(${bundle}/bin/jj log --ignore-working-copy --no-graph --revisions @ --template 'author.email()')" = "override@example.com"
            test "$(${bundle}/bin/jj file list --ignore-working-copy)" = "visible"
            touch $out
          '';

        pull-config-overrides =
          let
            bundle = nixbits.jujutsu.override {
              git-config = writeText "jj-pull-bundle-git-config" ''
                [core]
                excludesFile = ${writeText "jj-pull-bundle-gitignore" "ignored-by-override\n"}
              '';
              jujutsu-config = writeText "jj-pull-bundle-config.toml" ''
                [user]
                name = "Override Author"
                email = "override@example.com"
                [git]
                executable-path = "${lib.getExe git}"
              '';
            };
          in
          runCommand "test-jj-bundled-pull-config-overrides" { nativeBuildInputs = [ git ]; } ''
            export HOME="$PWD/home"
            unset GIT_CONFIG_GLOBAL JJ_CONFIG
            mkdir -p "$HOME"
            git init --initial-branch=main seed
            git -C seed config user.name "Seed Author"
            git -C seed config user.email "seed@example.com"
            git -C seed commit --allow-empty --message initial
            ${bundle}/bin/jj --config user.name='Seed Author' --config user.email=seed@example.com git clone "$PWD/seed" work

            git -C seed commit --allow-empty --message upstream
            upstream=$(git -C seed rev-parse HEAD)
            cd work
            touch visible ignored-by-override
            ${bundle}/bin/jj-pull

            test "$(${bundle}/bin/jj log --ignore-working-copy --no-graph --revisions '@-' --template 'commit_id')" = "$upstream"
            test "$(${bundle}/bin/jj log --ignore-working-copy --no-graph --revisions @ --template 'committer.name()')" = "Override Author"
            test "$(${bundle}/bin/jj log --ignore-working-copy --no-graph --revisions @ --template 'committer.email()')" = "override@example.com"
            test "$(${bundle}/bin/jj file list --ignore-working-copy)" = "visible"
            touch $out
          '';

        ignore = runCommand "test-jj-ignore" { nativeBuildInputs = [ jujutsu ]; } ''
          jj git init
          touch README.md
          mkdir .claude
          touch .claude/settings.local.json
          if ! jj file list | grep --quiet README.md; then
            echo "expected README.md to be tracked"
            return 1
          fi
          if jj file list | grep --quiet .claude/settings.local.json; then
            echo "expected .claude/settings.local.json to be ignored"
            return 1
          fi
          touch $out
        '';
      };
  }
)
