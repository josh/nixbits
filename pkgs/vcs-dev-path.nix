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
  # Compatibility: supplied entries replace whole credential sections, including module settings.
  extraGitCredentials ? { },
}:
let
  inherit (nixbits) gh;
  git = wlibEvalPackage [
    ../modules/git-wrapper.nix
    gitModule
    { settings.credential = lib.mapAttrs (_: lib.mkForce) extraGitCredentials; }
  ];
  git-config = git.configuration.constructFiles.gitconfig.outPath;
  jujutsu = wlibEvalPackage [
    ../modules/jujutsu-wrapper.nix
    ({ config, ... }: {
      gitWrapper = git;
      inherit (nixbits.jujutsu.configuration) jujutsuPackage watchmanPackage;
      commands = import ../modules/jujutsu-wrapper/commands.nix { inherit config nixbits; };
    })
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
      jj-package-overrides =
        let
          base = nixbits.jujutsu.configuration.jujutsuPackage;
          customJj = symlinkJoin {
            name = "custom-vcs-jj";
            inherit (base) version meta;
            paths = [ base ];
            postBuild = ''touch "$out/custom-jj-marker"'';
          };
          watchman = (writeShellScriptBin "watchman" "echo vcs-watchman") // {
            meta.available = true;
          };
          bundle = nixbits.vcs-dev-path.override {
            nixbits = nixbits // {
              jujutsu = wlibEvalPackage [
                ../modules/jujutsu-wrapper.nix
                {
                  jujutsuPackage = customJj;
                  watchmanPackage = watchman;
                }
              ];
            };
          };
        in
        runCommand "test-vcs-dev-path-jj-package-overrides" { } ''
          test -e ${bundle}/custom-jj-marker
          test "$(${bundle}/bin/watchman)" = vcs-watchman
          ${bundle}/bin/jj version
          touch "$out"
        '';

      credential-propagation-module = import ../modules/git-wrapper/vcs-dev-path-test.nix {
        inherit
          lib
          nixbits
          runCommand
          writeShellScriptBin
          ;
        useModule = true;
      };
      credential-propagation-legacy = import ../modules/git-wrapper/vcs-dev-path-test.nix {
        inherit
          lib
          nixbits
          runCommand
          writeShellScriptBin
          ;
        useModule = false;
      };

      jj-git-credentials =
        let
          bundle = nixbits.vcs-dev-path.override {
            extraGitCredentials."https://git.example.com" = {
              helper = [
                ""
                "test-credential-helper"
              ];
              useHttpPath = true;
            };
          };
        in
        runCommand "test-vcs-dev-path-jj-git-credentials" { } ''
          export HOME="$PWD/home"
          unset GIT_CONFIG_GLOBAL JJ_CONFIG
          mkdir -p "$HOME"
          selectedGit="$(${bundle}/bin/jj config get git.executable-path)"
          test "$selectedGit" = "$(readlink -f ${bundle}/bin/git)"
          test "$("$selectedGit" config get --url=https://git.example.com/repo.git credential.helper)" = "test-credential-helper"
          test "$("$selectedGit" config get --url=https://git.example.com/repo.git credential.useHttpPath)" = true
          touch $out
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
