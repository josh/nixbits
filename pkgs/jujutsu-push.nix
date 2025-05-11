{
  lib,
  writeShellApplication,
  git,
  jujutsu,
  nixbits,
}:
writeShellApplication {
  name = "jj-push";
  runtimeInputs = [
    git
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    JJ_CONFIG = nixbits.jujutsu-config;
  };
  text = builtins.readFile ./jujutsu-push.bash;
  meta = {
    description = "Push current jj revision to remote origin main branch";
    platforms = lib.platforms.all;
  };
}
