{
  lib,
  writeShellApplication,
  coreutils,
  git,
  jujutsu,
  nixbits,
}:
writeShellApplication {
  name = "jj-pull";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      git
      jujutsu
    ];
    JJ_CONFIG = nixbits.jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-pull.bash;
  meta = {
    description = "Pull jj git remote";
    platforms = lib.platforms.all;
  };
}
