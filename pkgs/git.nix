{
  lib,
  stdenv,
  symlinkJoin,
  makeWrapper,
  runCommand,
  testers,
  git,
  nixbits,
  git-config ? nixbits.git-config,
}:
let
  git' = symlinkJoin {
    pname = "git";
    inherit (git) version;

    __structuredAttrs = true;

    paths = [
      git
      nixbits.git-branch-prune
      nixbits.git-fetch-dir
    ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/git \
        --set GIT_CONFIG_GLOBAL "$gitConfig"
    '';

    meta = {
      inherit (git.meta)
        description
        homepage
        license
        platforms
        ;
      mainProgram = "git";
    };
  };
in
git'.overrideAttrs (
  finalAttrs: _previousAttrs: {
    gitConfig = git-config;

    passthru.tests =
      let
        git = finalAttrs.finalPackage;

        git-with-extra-credentials = finalAttrs.finalPackage.overrideAttrs {
          gitConfig = git-config.override {
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
  }
)
