{
  lib,
  writeShellApplication,
  jujutsu,
  nixbits,
}:
writeShellApplication {
  name = "jj-pull";
  runtimeInputs = [
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
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
