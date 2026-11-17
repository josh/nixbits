{
  lib,
  writeShellApplication,
  jujutsu,
  nixbits,
  git-config ? nixbits.git-config,
  jujutsu-config ? nixbits.jujutsu-config,
}:
writeShellApplication {
  name = "jj-pull";
  runtimeInputs = [
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = git-config;
    JJ_CONFIG = jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-pull.bash;

  meta = {
    description = "Pull jj git remote";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
