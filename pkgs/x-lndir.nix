{
  lib,
  writeShellApplication,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "x-lndir";
  runtimeInputs = [
    coreutils
  ];
  inheritPath = false;
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./x-lndir.bash;
  meta = {
    description = "Conditionally update directory of symlinks";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
