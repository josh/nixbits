{
  lib,
  writeShellApplication,
  coreutils,
  gawk,
  mas,
}:
writeShellApplication {
  name = "mas-activate";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      gawk
      mas
    ];
  };
  text = builtins.readFile ./mas-activate.bash;

  meta = {
    description = "Install Mac App Store Apps given a directory of App IDs";
    platforms = lib.platforms.darwin;
  };
}
