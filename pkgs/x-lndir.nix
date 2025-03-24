{
  lib,
  writeShellApplication,
  coreutils,
  findutils,
}:
writeShellApplication {
  name = "x-lndir";
  runtimeEnv = {
    "PATH" = lib.strings.makeBinPath [
      coreutils
      findutils
    ];
  };
  text = builtins.readFile ./x-lndir.bash;
  meta = {
    description = "Conditionally update directory of symlinks";
    platforms = lib.platforms.all;
  };
}
