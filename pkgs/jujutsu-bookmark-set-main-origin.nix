{
  lib,
  writeShellApplication,
  git,
  jujutsu,
  nixbits,
}:
writeShellApplication {
  name = "jj-bookmark-set-main-origin";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      git
      jujutsu
    ];
    JJ_CONFIG = nixbits.jujutsu-config;
  };
  text = builtins.readFile ./jujutsu-bookmark-set-main-origin.bash;
  meta = {
    description = "Push current jj revision to remote origin main branch";
    platforms = lib.platforms.all;
  };
}
