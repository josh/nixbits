{
  lib,
  writeShellApplication,
  git,
  jujutsu,
  nixbits,
}:
writeShellApplication {
  name = "jj-fetch";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      git
      jujutsu
    ];
    JJ_CONFIG = nixbits.jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-fetch.bash;
  meta = {
    description = "Fetch all jj git remotes";
    platforms = lib.platforms.all;
  };
}
