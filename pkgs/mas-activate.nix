{
  lib,
  writeShellApplication,
  coreutils,
  gawk,
  mas,
}:
writeShellApplication {
  name = "mas-activate";
  runtimeInputs = [
    coreutils
    gawk
    mas
  ];
  inheritPath = false;
  text = builtins.readFile ./mas-activate.bash;

  meta = {
    description = "Install Mac App Store Apps given a directory of App IDs";
    platforms = lib.platforms.darwin;
  };
}
