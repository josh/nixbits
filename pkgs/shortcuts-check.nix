{
  lib,
  writeShellApplication,
  gnugrep,
  nixbits,
}:
let
  inherit (nixbits.darwin) shortcuts;
in
writeShellApplication {
  name = "shortcuts-check";
  runtimeInputs = [
    gnugrep
    shortcuts
  ];
  inheritPath = false;
  text = builtins.readFile ./shortcuts-check.bash;
  meta = {
    description = "Check if macOS Shortcut is available";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
}
