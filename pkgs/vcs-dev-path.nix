{
  lib,
  symlinkJoin,
  runCommand,
  jjui,
  tea,
  nur,
  nixbits,
  gitea-cli ? nur.repos.josh.gitea-cli,
  extraGitCredentials ? { },
}:
let
  inherit (nixbits) gh lazyjj;
  git-config = nixbits.git-config.override { extraCredentials = extraGitCredentials; };
  git = nixbits.git.override { inherit git-config; };
  jujutsu-config = nixbits.jujutsu-config.override { git-package = git; };
  jujutsu = nixbits.jujutsu.override { inherit git-config jujutsu-config; };
  lazygit = nixbits.lazygit.override { inherit git-config; };

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
    passthru.tests = {
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
