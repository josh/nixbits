{
  lib,
  symlinkJoin,
  wlibEvalPackage,
  runCommand,
  testers,
  writeText,
  writeShellScriptBin,
  git,
  jujutsu,
  watchman,
  nixbits,
  git-config ? nixbits.git-config,
  jujutsu-config ? nixbits.jujutsu-config,
}:
wlibEvalPackage [
  ../modules/jujutsu-wrapper.nix
  ({ config, ... }: {
    package = symlinkJoin {
      pname = "jujutsu";
      inherit (jujutsu) version meta;

      paths = [
        jujutsu
        (nixbits.jujutsu-bookmark-clean.override {
          inherit git-config jujutsu-config;
        })
        (nixbits.jujutsu-clone.override {
          inherit git-config jujutsu-config;
        })
        (nixbits.jujutsu-git-set-upstream.override { inherit git-config; })
        (nixbits.jujutsu-untracked.override {
          inherit git-config jujutsu-config;
        })
        (nixbits.jujutsu-wip-changes.override {
          inherit git-config jujutsu-config;
        })
      ]
      ++ (lib.lists.optional watchman.meta.available watchman);
    };
    configFile.path = jujutsu-config;
    env.GIT_CONFIG_GLOBAL = "${git-config}";

    passthru.tests =
      let
        jujutsu = config.wrapper;
        mkUntrackedOverrideTest =
          name: initArgs:
          let
            bundle = nixbits.jujutsu.override {
              git-config = writeText "jj-untracked-bundle-git-config" ''
                [core]
                excludesFile = ${writeText "jj-untracked-bundle-gitignore" "tracked-ignored.txt\n"}
              '';
              jujutsu-config = writeText "jj-untracked-bundle-config.toml" ''
                [user]
                name = "Override Author"
                email = "override@example.com"
                [snapshot]
                auto-track = "glob:tracked*"
              '';
            };
          in
          runCommand "test-jj-bundled-untracked-${name}-config-overrides" { } ''
            export HOME="$PWD/home"
            unset GIT_CONFIG_GLOBAL JJ_CONFIG
            mkdir -p "$HOME" repo
            cd repo
            ${bundle}/bin/jj git init ${initArgs}
            touch tracked.txt tracked-ignored.txt manual.txt

            actual="$(${bundle}/bin/jj-untracked)"
            expected=$(printf 'manual.txt\ntracked-ignored.txt')
            if [[ "$actual" != "$expected" ]]; then
              echo "expected '$expected' but was '$actual'" >&2
              exit 1
            fi
            test "$(${bundle}/bin/jj file list --ignore-working-copy)" = "tracked.txt"
            touch $out
          '';
      in
      {
        untracked-colocated-config-overrides = mkUntrackedOverrideTest "colocated" "--colocate";
        untracked-non-colocated-config-overrides = mkUntrackedOverrideTest "non-colocated" "--no-colocate";

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
          let
            customConfig = writeText "jj-override.toml" ''
              [user]
              name = "Override Author"
              email = "override@example.com"
            '';
            customPackage = nixbits.jujutsu.override { jujutsu-config = customConfig; };
            customModule = wlibEvalPackage [
              ../modules/jujutsu-wrapper.nix
              { configFile.path = customConfig; }
            ];
          in
          runCommand "test-jj-config-override" { } ''
            export HOME="$TMPDIR/home" JJ_CONFIG=/ignored/jj-config
            mkdir -p "$HOME"
            for jjBin in ${customPackage}/bin/jj ${customModule}/bin/jj; do
              test "$("$jjBin" config get user.name)" = "Override Author"
              test "$("$jjBin" config get user.email)" = "override@example.com"
            done
            touch "$out"
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

        new-main-config-overrides =
          let
            bundle = nixbits.jujutsu.override {
              git-config = writeText "jj-new-main-bundle-git-config" ''
                [core]
                excludesFile = ${writeText "jj-new-main-bundle-gitignore" "ignored-by-override\n"}
              '';
              jujutsu-config = writeText "jj-new-main-bundle-config.toml" ''
                [user]
                name = "Override Author"
                email = "override@example.com"
                [git]
                executable-path = "${lib.getExe git}"
              '';
            };
          in
          runCommand "test-jj-bundled-new-main-config-overrides" { nativeBuildInputs = [ git ]; } ''
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
            previous=$(${bundle}/bin/jj log --ignore-working-copy --no-graph --revisions @ --template 'change_id')
            touch visible ignored-by-override
            ${bundle}/bin/jj-new-main

            test "$(${bundle}/bin/jj log --ignore-working-copy --no-graph --revisions '@-' --template 'commit_id')" = "$upstream"
            test "$(${bundle}/bin/jj log --ignore-working-copy --no-graph --revisions @ --template 'change_id')" != "$previous"
            test "$(${bundle}/bin/jj log --ignore-working-copy --no-graph --revisions @ --template 'author.name()')" = "Override Author"
            test "$(${bundle}/bin/jj log --ignore-working-copy --no-graph --revisions @ --template 'author.email()')" = "override@example.com"
            test "$(${bundle}/bin/jj file list --ignore-working-copy --revision "$previous")" = "visible"
            touch $out
          '';

        wip-changes-config-overrides =
          let
            bundle = nixbits.jujutsu.override {
              git-config = writeText "jj-wip-changes-bundle-git-config" ''
                [core]
                excludesFile = ${writeText "jj-wip-changes-bundle-gitignore" "tracked-ignored.txt\n"}
              '';
              jujutsu-config = writeText "jj-wip-changes-bundle-config.toml" ''
                [user]
                name = "Override Author"
                email = "override@example.com"
                [snapshot]
                auto-track = "glob:tracked*"
                [revset-aliases]
                "trunk()" = "root()"
              '';
            };
          in
          runCommand "test-jj-bundled-wip-changes-config-overrides" { } ''
            export HOME="$PWD/home"
            unset GIT_CONFIG_GLOBAL JJ_CONFIG
            mkdir -p "$HOME" repo
            cd repo
            ${bundle}/bin/jj git init
            test -z "$(${bundle}/bin/jj-wip-changes)"

            touch manual.txt tracked-ignored.txt
            test -z "$(${bundle}/bin/jj-wip-changes)"
            touch tracked.txt
            expected="$(${bundle}/bin/jj log --ignore-working-copy --no-graph --revisions @ --template 'change_id.short(8)')*"
            actual="$(${bundle}/bin/jj-wip-changes)"
            if [[ "$actual" != "$expected" ]]; then
              echo "expected '$expected' but was '$actual'" >&2
              exit 1
            fi
            test "$(${bundle}/bin/jj file list --ignore-working-copy)" = "tracked.txt"
            touch $out
          '';

        bookmark-clean-config-overrides =
          let
            bundle = nixbits.jujutsu.override {
              git-config = writeText "jj-bookmark-clean-bundle-git-config" ''
                [core]
                excludesFile = ${writeText "jj-bookmark-clean-bundle-gitignore" "ignored-by-override\n"}
              '';
              jujutsu-config = writeText "jj-bookmark-clean-bundle-config.toml" ''
                [user]
                name = "Override Author"
                email = "override@example.com"
                [revset-aliases]
                "trunk()" = "@-"
              '';
            };
          in
          runCommand "test-jj-bundled-bookmark-clean-config-overrides" { nativeBuildInputs = [ jujutsu ]; } ''
            export HOME="$PWD/home"
            unset GIT_CONFIG_GLOBAL JJ_CONFIG
            mkdir -p "$HOME" repo
            cd repo
            jj git init
            jj describe --message base
            jj bookmark create main master
            jj new
            jj describe --message merged
            jj bookmark create push-merged
            jj new
            jj bookmark create push-unmerged
            touch visible ignored-by-override
            ${bundle}/bin/jj-bookmark-clean

            actual="$(${bundle}/bin/jj bookmark list --ignore-working-copy --template 'name ++ "\n"')"
            expected=$(printf 'main\nmaster\npush-unmerged')
            if [[ "$actual" != "$expected" ]]; then
              echo "expected '$expected' but was '$actual'" >&2
              exit 1
            fi
            test "$(${bundle}/bin/jj file list --ignore-working-copy)" = "visible"
            touch $out
          '';

        clone-config-overrides =
          let
            bundle = nixbits.jujutsu.override {
              nixbits = nixbits // {
                jujutsu-clone = nixbits.jujutsu-clone.override {
                  nixbits = nixbits // {
                    gh = writeShellScriptBin "gh" ''
                      test "$#" -eq 5 && test "$1" = repo && test "$2" = view &&
                        test "$3" = "$TEST_REPO_URL" && test "$4" = --json &&
                        test "$5" = isFork,repositoryTopics || exit 1
                      touch "$GH_STUB_CALLED"
                      printf '%s\n' '{"isFork":false,"repositoryTopics":[]}'
                    '';
                  };
                };
              };
              git-config = writeText "jj-clone-bundle-git-config" ''
                [url "file:///"]
                insteadOf = localtest:///
              '';
              jujutsu-config = writeText "jj-clone-bundle-config.toml" ''
                [user]
                name = "Override Author"
                email = "override@example.com"
                [git]
                executable-path = "${lib.getExe git}"
              '';
            };
          in
          runCommand "test-jj-bundled-clone-config-overrides" { nativeBuildInputs = [ git ]; } ''
            export HOME="$PWD/home"
            unset GIT_CONFIG_GLOBAL JJ_CONFIG GT
            mkdir -p "$HOME"
            git init --initial-branch=main seed
            git -C seed config user.name "Seed Author"
            git -C seed config user.email "seed@example.com"
            git -C seed commit --allow-empty --message initial
            upstream=$(git -C seed rev-parse HEAD)
            export TEST_REPO_URL="localtest://$PWD/seed" GH_STUB_CALLED="$PWD/gh-called"
            ${bundle}/bin/jj-clone "$TEST_REPO_URL" work

            test -f "$GH_STUB_CALLED"
            cd work
            test "$(${bundle}/bin/jj log --ignore-working-copy --no-graph --revisions '@-' --template 'commit_id')" = "$upstream"
            test "$(${bundle}/bin/jj log --ignore-working-copy --no-graph --revisions @ --template 'author.name()')" = "Override Author"
            test "$(${bundle}/bin/jj log --ignore-working-copy --no-graph --revisions @ --template 'author.email()')" = "override@example.com"
            touch $out
          '';

        upstream-git-config-override =
          let
            bundle = nixbits.jujutsu.override {
              nixbits = nixbits // {
                jujutsu-git-set-upstream = nixbits.jujutsu-git-set-upstream.override {
                  nixbits = nixbits // {
                    gh = writeShellScriptBin "gh" ''
                      test "$#" -eq 7 && test "$1" = repo && test "$2" = view &&
                        test "$4" = --json && test "$6" = --jq || exit 1
                      test "$JJ_CONFIG" = "$EXPECTED_JJ_CONFIG" || exit 1
                      case "$5" in
                      isFork)
                        test "$3" = "$TEST_ORIGIN_URL" || exit 1
                        echo true
                        ;;
                      parent)
                        test "$3" = "$TEST_ORIGIN_URL" || exit 1
                        echo "$TEST_UPSTREAM_URL"
                        ;;
                      defaultBranchRef)
                        test "$3" = "$TEST_UPSTREAM_URL" || exit 1
                        echo main
                        ;;
                      *) exit 1 ;;
                      esac
                      echo "$5" >>"$GH_STUB_CALLS"
                    '';
                  };
                };
              };
              git-config = writeText "jj-upstream-bundle-git-config" ''
                [url "file:///"]
                insteadOf = https://github.com/upstream/
              '';
            };
            inheritedConfig = writeText "jj-upstream-bundle-inherited.toml" ''
              [user]
              name = "Inherited Author"
              email = "inherited@example.com"
              [snapshot]
              auto-track = "glob:tracked*"
            '';
          in
          runCommand "test-jj-bundled-upstream-git-config-override"
            {
              nativeBuildInputs = [
                git
                jujutsu
              ];
            }
            ''
              export HOME="$PWD/home" JJ_CONFIG=${inheritedConfig} EXPECTED_JJ_CONFIG=${inheritedConfig}
              unset GIT_CONFIG_GLOBAL
              mkdir -p "$HOME"
              git init --initial-branch=main seed
              git -C seed config user.name "Seed Author"
              git -C seed config user.email "seed@example.com"
              git -C seed commit --allow-empty --message initial
              jj git clone "$PWD/seed" work
              git -C seed commit --allow-empty --message upstream
              upstream=$(git -C seed rev-parse HEAD)
              export TEST_ORIGIN_URL=https://github.com/example/fork.git
              export TEST_UPSTREAM_URL="https://github.com/upstream$PWD/seed" GH_STUB_CALLS="$PWD/gh-calls"
              cd work
              jj git remote set-url origin "$TEST_ORIGIN_URL"
              touch tracked.txt manual.txt
              ${bundle}/bin/jj-git-set-upstream

              test "$(cat "$GH_STUB_CALLS")" = "$(printf 'isFork\nparent\ndefaultBranchRef')"
              test "$(jj git remote list --ignore-working-copy | grep '^upstream ')" = "upstream $TEST_UPSTREAM_URL"
              test "$(jj config get 'revset-aliases."trunk()"')" = "main@upstream"
              test "$(jj log --ignore-working-copy --no-graph --revisions main@upstream --template 'commit_id')" = "$upstream"
              test "$(jj file list --ignore-working-copy)" = "tracked.txt"
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
  })
]
