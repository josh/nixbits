{
  lib,
  writeShellApplication,
  coreutils,
  git,
  jujutsu,
  nixbits,
}:
writeShellApplication {
  name = "jj-clone";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      git
      jujutsu
    ];
    JJ_CONFIG = nixbits.jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-clone.bash;
  meta = {
    description = "Clone a jj repository";
    platforms = lib.platforms.all;
  };
}
