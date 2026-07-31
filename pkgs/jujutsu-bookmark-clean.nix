{
  lib,
  writeShellApplication,
  jujutsu,
  nixbits,
}:
writeShellApplication {
  name = "jj-bookmark-clean";
  runtimeInputs = [
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    JJ_CONFIG = nixbits.jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-bookmark-clean.bash;
  meta = {
    description = "Clean up merged jj push-* bookmarks";
    platforms = lib.platforms.all;
  };
}
