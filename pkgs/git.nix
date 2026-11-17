{
  lib,
  stdenv,
  wlibEvalPackage,
  writeText,
  runCommand,
  testers,
  nixbits,
  git-config ? nixbits.git-config,
}:
wlibEvalPackage [
  ../modules/git-wrapper.nix
  ({ config, ... }: {
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
            customModule = wlibEvalPackage [
              ../modules/git-wrapper.nix
              { configFile.path = customConfig; }
            ];
          in
          runCommand "test-git-config-override" { nativeBuildInputs = [ customGit ]; } ''
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"
            export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/ignored/git-config
            for gitBin in ${customGit}/bin/git ${customModule}/bin/git; do
              test "$("$gitBin" config get user.name)" = "Custom Git User"
              test "$("$gitBin" config get user.email)" = custom@example.com
              test "$("$gitBin" config get --url=https://git.example.com credential.helper)" = custom-helper
              test "$("$gitBin" config get --show-origin user.name)" = "$(printf 'file:%s\t%s' ${customConfig} 'Custom Git User')"
            done
            touch "$out"
          '';

        direct-module-helpers = (wlibEvalPackage ../modules/git-wrapper.nix).tests.bundled-helpers;

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
