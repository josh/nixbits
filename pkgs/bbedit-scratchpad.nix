{
  lib,
  writeShellApplication,
  nixbits,
}:
writeShellApplication {
  name = "bbedit-scratchpad";
  runtimeInputs = [ nixbits.darwin.osascript ];
  inheritPath = false;
  text = ''
    osascript <${./bbedit-scratchpad.applescript}
  '';
  meta = {
    description = "Open BBEdit's scratchpad document";
    platforms = lib.platforms.darwin;
  };
}
