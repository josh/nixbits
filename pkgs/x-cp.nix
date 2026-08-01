{
  lib,
  writeShellApplication,
  coreutils,
  diffutils,
  nixbits,
}:
writeShellApplication {
  name = "x-cp";
  runtimeInputs = [
    coreutils
    diffutils
  ];
  inheritPath = false;
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./x-cp.bash;
  meta = {
    description = "Conditionally copy files";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
