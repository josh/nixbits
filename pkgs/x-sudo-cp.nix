{
  lib,
  writeShellApplication,
  coreutils,
  diffutils,
  nixbits,
  overrideSudo ? nixbits.sudo,
}:
writeShellApplication {
  name = "x-sudo-cp";
  runtimeInputs = [
    coreutils
    diffutils
    overrideSudo
  ];
  inheritPath = false;
  runtimeEnv = {
    COREUTILS_PATH = coreutils;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./x-sudo-cp.bash;
  meta = {
    description = "Conditionally copy files with sudo";
    platforms = lib.platforms.all;
  };
}
