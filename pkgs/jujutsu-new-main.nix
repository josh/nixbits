{
  lib,
  writeShellApplication,
  jujutsu,
  nixbits,
  git-config ? nixbits.git-config,
  jujutsu-config ? nixbits.jujutsu-config,
}:
writeShellApplication {
  name = "jj-new-main";
  runtimeInputs = [
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = git-config;
    JJ_CONFIG = jujutsu-config;
  };
  text = builtins.readFile ./jujutsu-new-main.bash;

  meta = {
    description = "Fetch origin then create new change from main@origin";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
