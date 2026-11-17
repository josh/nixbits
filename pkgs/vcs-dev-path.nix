{
  lib,
  symlinkJoin,
  wlibEvalPackage,
  runCommand,
  writeShellScriptBin,
  jjui,
  tea,
  nur,
  nixbits,
  gitea-cli ? nur.repos.josh.gitea-cli,
  gitModule ? { },
  jujutsuModule ? { },
}:
let
  inherit (nixbits) gh;
  git = wlibEvalPackage [
    ../modules/wrappers/git.nix
    gitModule
  ];
  git-config = git.configuration.constructFiles.gitconfig.outPath;
  jujutsu = wlibEvalPackage [
    ../modules/wrappers/jujutsu.nix
    { gitWrapper = git; }
    jujutsuModule
  ];
  jujutsu-config = jujutsu.configuration.configFile.path;
  lazygit = nixbits.lazygit.override { inherit git-config; };
  lazyjj = nixbits.lazyjj.override { inherit git-config jujutsu-config; };

  vcs-dev-path = symlinkJoin {
    name = "vcs-dev-path";
    paths = [
      # keep-sorted start
      gh
      git
      gitea-cli
      jjui
      jujutsu
      lazygit
      lazyjj
      tea
      # keep-sorted end
    ];
    meta = {
      description = "Bundle of version control tools";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  };
in
vcs-dev-path.overrideAttrs (
  finalAttrs: _previousAttrs: {
    # Let downstreams reuse the exact packages and config files selected by this bundle.
    passthru.git = git;
    passthru.jujutsu = jujutsu;
    passthru.tests = {
      credential-propagation-module =
        let
          credentials."https://git.example.com" = {
            helper = [
              ""
              "test-credential-helper"
            ];
            useHttpPath = true;
          };
          # Probe the environment at each application's real launch boundary.
          lazygitProbe =
            (writeShellScriptBin "lazygit" ''
              set -eu
              test "$GIT_CONFIG_GLOBAL" = "$EXPECTED_GIT_CONFIG"
              test "$(git config get --url=https://git.example.com/repo.git credential.helper)" = test-credential-helper
              test "$(git config get --url=https://git.example.com/repo.git credential.useHttpPath)" = true
              printf '%s\n' passed >"$PROBE_PASSED"
            '').overrideAttrs
              {
                pname = "lazygit";
                inherit (nixbits.lazygit) version meta;
              };
          lazyjjProbe =
            (writeShellScriptBin "lazyjj" ''
              set -eu
              test "$GIT_CONFIG_GLOBAL" = "$EXPECTED_GIT_CONFIG"
              test "$JJ_CONFIG" = "$EXPECTED_JJ_CONFIG"
              selectedGit="$(jj config get git.executable-path)"
              test "$selectedGit" = "$EXPECTED_GIT"
              test "$("$selectedGit" config get --url=https://git.example.com/repo.git credential.helper)" = test-credential-helper
              test "$("$selectedGit" config get --url=https://git.example.com/repo.git credential.useHttpPath)" = true
              printf '%s\n' passed >"$PROBE_PASSED"
            '').overrideAttrs
              {
                pname = "lazyjj";
                inherit (nixbits.lazyjj) version;
              };
          bundle = nixbits.vcs-dev-path.override {
            nixbits = nixbits // {
              lazygit = nixbits.lazygit.override { lazygit = lazygitProbe; };
              lazyjj = nixbits.lazyjj.override { lazyjj = lazyjjProbe; };
            };
            gitModule = { lib, ... }: {
              settings = {
                user = {
                  name = lib.mkForce "Module Author";
                  email = lib.mkForce "module@example.com";
                };
                credential = credentials;
              };
            };
          };
        in
        runCommand "test-vcs-dev-path-credential-propagation-module" { } ''
          export HOME="$PWD/home" GIT_CONFIG_NOSYSTEM=1
          mkdir -p "$HOME"
          export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
          export EXPECTED_GIT_CONFIG=${bundle.git.configuration.constructFiles.gitconfig.outPath}
          export EXPECTED_JJ_CONFIG=${bundle.jujutsu.configuration.configFile.path}
          export EXPECTED_GIT=${lib.getExe bundle.git}
          test "$(readlink -f ${bundle}/bin/git)" = "$EXPECTED_GIT"
          test "$(${bundle}/bin/git config get user.name)" = 'Module Author'
          test "$(${bundle}/bin/git config get --url=https://git.example.com/repo.git credential.helper)" = test-credential-helper
          test "$(${bundle}/bin/git config get --url=https://git.example.com/repo.git credential.useHttpPath)" = true
          test "$(${bundle}/bin/jj config get user.name)" = 'Module Author'
          test "$(${bundle}/bin/jj config get user.email)" = module@example.com
          test "$(${bundle}/bin/jj config get git.executable-path)" = "$EXPECTED_GIT"
          for app in lazygit lazyjj; do
            export PROBE_PASSED="$PWD/$app-passed"
            ${bundle}/bin/"$app" >/dev/null
            test -f "$PROBE_PASSED"
          done
          touch "$out"
        '';

      git-config = runCommand "test-vcs-dev-path-git-config" { } ''
        for bin in git jj lazygit; do
          if ! grep --quiet 'GIT_CONFIG_GLOBAL.*${git-config}' ${finalAttrs.finalPackage}/bin/$bin; then
            echo "expected $bin to be wrapped with GIT_CONFIG_GLOBAL=${git-config}"
            return 1
          fi
        done
        touch $out
      '';

      gt =
        runCommand "test-vcs-dev-path-gt"
          {
            nativeBuildInputs = [ finalAttrs.finalPackage ];
            GITEA_CLI_NO_UPDATE_NOTIFIER = "1";
          }
          ''
            export GITEA_CLI_CONFIG_DIR=$TMPDIR/gt
            gt --version
            gt auth git-credential --help
            touch $out
          '';

      tea =
        runCommand "test-vcs-dev-path-tea"
          {
            nativeBuildInputs = [ finalAttrs.finalPackage ];
          }
          ''
            tea --version
            tea logins helper --help
            touch $out
          '';
    };
  }
)
