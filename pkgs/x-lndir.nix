{
  lib,
  writeShellApplication,
  coreutils,
  findutils,
  nixbits,
}:
writeShellApplication {
  name = "x-lndir";
  runtimeEnv = {
    "PATH" = lib.strings.makeBinPath [
      coreutils
      findutils
    ];
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./x-lndir.bash;
  meta = {
    description = "Conditionally update directory of symlinks";
    platforms = lib.platforms.all;
  };
}
