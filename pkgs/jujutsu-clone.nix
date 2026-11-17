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
  jujutsu-config ? nixbits.jujutsu-config,
  jujutsu-git-set-upstream ? nixbits.jujutsu-git-set-upstream.override { inherit git-config; },
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
    jujutsu-git-set-upstream
  ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = git-config;
    JJ_CONFIG = jujutsu-config;
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
