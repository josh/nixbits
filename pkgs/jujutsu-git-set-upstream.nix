{
  lib,
  writeShellApplication,
  coreutils,
  git,
  gnugrep,
  jujutsu,
  nixbits,
  git-config ? nixbits.git-config,
}:
let
  inherit (nixbits) gh;
in
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
    GIT_CONFIG_GLOBAL = git-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-git-set-upstream.bash;

  meta = {
    description = "Automatically configure jj git upstream remote";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
