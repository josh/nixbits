{
  lib,
  writeShellApplication,
  coreutils,
  gh,
  git,
  gnugrep,
  jujutsu,
  nixbits,
}:
writeShellApplication {
  name = "jj-git-set-upstream";
  runtimeInputs = [
    coreutils
    gh
    git
    gnugrep
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-git-set-upstream.bash;
  meta = {
    description = "Automatically configure jj git upstream remote";
    platforms = lib.platforms.all;
  };
}
