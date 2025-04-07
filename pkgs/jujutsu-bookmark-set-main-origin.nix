{
  lib,
  writeShellApplication,
  git,
  jujutsu,
}:
writeShellApplication {
  name = "jj-bookmark-set-main-origin";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      git
      jujutsu
    ];
  };
  text = builtins.readFile ./jujutsu-bookmark-set-main-origin.bash;
  meta = {
    description = "Push current jj revision to remote origin main branch";
    platforms = lib.platforms.all;
  };
}
