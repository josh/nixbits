{
  lib,
  writeShellApplication,
  coreutils,
  git,
  jujutsu,
  nixbits,
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
    jujutsu
    nixbits.jujutsu-git-set-upstream
  ];
  inheritPath = false;
  runtimeEnv = {
    JJ_CONFIG = nixbits.jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-clone.bash;
  meta = {
    description = "Clone a jj repository";
    platforms = lib.platforms.all;
  };
}
