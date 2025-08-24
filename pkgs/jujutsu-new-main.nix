{
  lib,
  writeShellApplication,
  jujutsu,
  nixbits,
}:
writeShellApplication {
  name = "jj-new-main";
  runtimeInputs = [
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    JJ_CONFIG = nixbits.jujutsu-config;
  };
  text = builtins.readFile ./jujutsu-new-main.bash;
  meta = {
    description = "Fetch origin then create new change from main@origin";
    platforms = lib.platforms.all;
  };
}
