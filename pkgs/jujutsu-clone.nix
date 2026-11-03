{
  lib,
  writeShellApplication,
  coreutils,
  git,
  jq,
  jujutsu,
  nur,
  nixbits,
  git-config ? nixbits.git-config,
  gitea-cli ? nur.repos.josh.gitea-cli,
  enableGitea ? false,
}:
let
  inherit (nixbits) gh;
in
writeShellApplication {
  name = "jj-clone";
  runtimeInputs = [
    coreutils
    gh
    git
    jq
    jujutsu
    nixbits.jujutsu-git-set-upstream
  ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = git-config;
    JJ_CONFIG = nixbits.jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  }
  // lib.attrsets.optionalAttrs enableGitea {
    GT = lib.getExe gitea-cli;
  };
  text = builtins.readFile ./jujutsu-clone.bash;
  meta = {
    description = "Clone a jj repository";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
