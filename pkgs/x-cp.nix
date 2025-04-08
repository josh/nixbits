{
  lib,
  writeShellApplication,
  coreutils,
  diffutils,
  nixbits,
}:
writeShellApplication {
  name = "x-cp";
  runtimeEnv = {
    "PATH" = lib.strings.makeBinPath [
      coreutils
      diffutils
    ];
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./x-cp.bash;
  meta = {
    description = "Conditionally copy files";
    platforms = lib.platforms.all;
  };
}
