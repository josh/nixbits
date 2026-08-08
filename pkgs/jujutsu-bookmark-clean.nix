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
    GIT_CONFIG_GLOBAL = nixbits.git-config;
    JJ_CONFIG = nixbits.jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-bookmark-clean.bash;
  meta = {
    description = "Clean up merged jj push-* bookmarks";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
