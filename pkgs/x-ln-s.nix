{
  lib,
  writeShellApplication,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "x-ln-s";
  runtimeInputs = [
    coreutils
  ];
  inheritPath = false;
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./x-ln-s.bash;
  meta = {
    description = "Conditionally update symlink";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
