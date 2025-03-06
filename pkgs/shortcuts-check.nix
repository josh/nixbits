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
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      gnugrep
      shortcuts
    ];
  };
  text = builtins.readFile ./shortcuts-check.bash;
  meta = {
    description = "Check if macOS Shortcut is available";
    platforms = lib.platforms.darwin;
  };
}
