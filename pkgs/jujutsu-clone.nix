{
  lib,
  writeShellApplication,
  coreutils,
  git,
  jq,
  jujutsu,
  tea,
  nixbits,
  git-config ? nixbits.git-config,
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
    TEA = lib.getExe tea;
  };
  text = builtins.readFile ./jujutsu-clone.bash;
  meta = {
    description = "Clone a jj repository";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
