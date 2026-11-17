{
  lib,
  stdenv,
  symlinkJoin,
  wlibEvalPackage,
  writeText,
  runCommand,
  testers,
  git,
  nixbits,
  git-config ? nixbits.git-config,
}:
wlibEvalPackage [
  ../modules/git-wrapper.nix
  ({ config, ... }: {
    package = symlinkJoin {
      pname = "git";
      inherit (git) version meta;
      paths = [
        git
        nixbits.git-branch-prune
        nixbits.git-fetch-dir
      ];
    };
    configFile.path = git-config;
    passthru.tests =
      let
        git = config.wrapper;

        git-with-extra-credentials = nixbits.git.override {
          git-config = git-config.override {
            extraCredentials = {
              "https://git.example.com".helper = [
                ""
                "example-credential-helper"
              ];
            };
          };
        };
      in
      {
        config-override =
          let
            customConfig = writeText "custom-git-config" ''
              [user]
                name = Custom Git User
                email = custom@example.com
              [credential "https://git.example.com"]
                helper =
                helper = custom-helper
            '';
            customGit = nixbits.git.override { git-config = customConfig; };
          in
          runCommand "test-git-config-override" { nativeBuildInputs = [ customGit ]; } ''
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"
            export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/ignored/git-config
            test "$(git config get user.name)" = "Custom Git User"
            test "$(git config get user.email)" = custom@example.com
            test "$(git config get --url=https://git.example.com credential.helper)" = custom-helper
            test "$(git config get --show-origin user.name)" = "$(printf 'file:%s\t%s' ${customConfig} 'Custom Git User')"
            touch "$out"
          '';

        bundled-helpers = runCommand "test-git-bundled-helpers" { nativeBuildInputs = [ git ]; } ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"
          export GIT_CONFIG_NOSYSTEM=1
          unset GIT_CONFIG_GLOBAL
          test -x ${git}/bin/git-branch-prune
          test -x ${git}/bin/git-fetch-dir
          git init -b main repo
          cd repo
          git commit --allow-empty -m initial
          git branch merged
          git branch-prune
          if git show-ref --verify --quiet refs/heads/merged; then
            echo "bundled branch-prune did not delete the merged branch"
            exit 1
          fi
          cd ..
          git init --bare remote.git
          git -C repo remote add origin "$PWD/remote.git"
          git -C repo push origin main
          git -C repo update-ref -d refs/remotes/origin/main
          git fetch-dir "$PWD/repo"
          test "$(git -C repo rev-parse origin/main)" = "$(git -C repo rev-parse main)"
          touch "$out"
        '';

        version = testers.testVersion {
          package = git;
          command = "git version";
          inherit (git) version;
        };

        author = runCommand "test-git-author" { nativeBuildInputs = [ git ]; } ''
          expected="Joshua Peek"
          actual="$(git config get user.name)"
          if [[ "$actual" != "$expected" ]]; then
            echo "expected, '$expected' but was '$actual'"
            return 1
          fi
          touch $out
        '';

        default-branch = runCommand "test-git-default-branch" { nativeBuildInputs = [ git ]; } ''
          git init
          if [[ "$(git branch --show-current)" != "main" ]]; then
            echo "expected, 'main' but was '$(git branch --show-current)'"
            return 1
          fi
          touch $out
        '';

        ignore = runCommand "test-git-ignore" { nativeBuildInputs = [ git ]; } ''
          git init
          touch README.md
          mkdir .claude
          touch .claude/settings.local.json
          if git check-ignore README.md; then
            echo "expected README.md to not be ignored"
            return 1
          fi
          if ! git check-ignore .claude/settings.local.json; then
            echo "expected .claude/settings.local.json to be ignored"
            return 1
          fi
          touch $out
        '';

        credential-helpers = runCommand "test-git-credential-helpers" { nativeBuildInputs = [ git ]; } ''
          expected="${lib.getExe nixbits.gh} auth git-credential"
          for url in https://github.com https://gist.github.com; do
            actual="$(git config get --url=$url credential.helper)"
            if [[ "$actual" != "$expected" ]]; then
              echo "expected, '$expected' but was '$actual' for $url"
              return 1
            fi
          done
          touch $out
        '';

        extra-credentials =
          runCommand "test-git-extra-credentials" { nativeBuildInputs = [ git-with-extra-credentials ]; }
            ''
              expected="example-credential-helper"
              actual="$(git config get --url=https://git.example.com credential.helper)"
              if [[ "$actual" != "$expected" ]]; then
                echo "expected, '$expected' but was '$actual'"
                return 1
              fi

              if git config get --url=https://github.com credential.helper | grep --quiet example-credential-helper; then
                echo "expected 'example-credential-helper' to not apply to github.com"
                return 1
              fi

              expected="${lib.getExe nixbits.gh} auth git-credential"
              actual="$(git config get --url=https://github.com credential.helper)"
              if [[ "$actual" != "$expected" ]]; then
                echo "expected, '$expected' but was '$actual'"
                return 1
              fi
              ${lib.strings.optionalString stdenv.hostPlatform.isDarwin ''

                actual="$(git config get --url=https://example.com credential.helper)"
                if [[ "$actual" != "osxkeychain" ]]; then
                  echo "expected, 'osxkeychain' but was '$actual'"
                  return 1
                fi
                actual="$(git config get --url=https://git.example.com credential.helper)"
                if [[ "$actual" == "osxkeychain" ]]; then
                  echo "expected 'osxkeychain' to be reset for git.example.com"
                  return 1
                fi
              ''}

              touch $out
            '';
      };
  })
]
