{
  lib,
  writeShellApplication,
  coreutils,
  git,
  jujutsu,
  nixbits,
}:
writeShellApplication {
  name = "jj-pull";
  runtimeInputs = [
    coreutils
    git
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    JJ_CONFIG = nixbits.jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-pull.bash;
  meta = {
    description = "Pull jj git remote";
    platforms = lib.platforms.all;
  };
}
