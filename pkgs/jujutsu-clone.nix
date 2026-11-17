{
  lib,
  writeShellApplication,
  wlibEvalPackage,
  coreutils,
  git,
  jq,
  jujutsu,
  nur,
  nixbits,
  jjConfiguration ? nixbits.jujutsu.configuration,
  jujutsu-git-set-upstream ? jjConfiguration.commands.jj-git-set-upstream,
  gitea-cli ? nur.repos.josh.gitea-cli,
  enableGitea ? false,
}:
let
  inherit (nixbits) gh;
  commandEnv = import ../modules/wrappers/jujutsu/command-env.nix {
    inherit lib git wlibEvalPackage;
  };
in
writeShellApplication {
  name = "jj-clone";
  runtimeInputs = [
    coreutils
    gh
    git
    jq
    jujutsu
    jujutsu-git-set-upstream
  ];
  inheritPath = false;
  runtimeEnv =
    commandEnv jjConfiguration
    // {
      XTRACE_PATH = nixbits.xtrace;
    }
    // lib.optionalAttrs enableGitea { GT = lib.getExe gitea-cli; };
  text = builtins.readFile ./jujutsu-clone.bash;

  meta = {
    description = "Clone a jj repository";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
