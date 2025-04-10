{
  lib,
  writeShellApplication,
  nixbits,
}:
writeShellApplication {
  name = "bbedit-scratchpad";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [ nixbits.darwin.osascript ];
  };
  text = ''
    osascript <${./bbedit-scratchpad.applescript}
  '';
  meta = {
    description = "Open BBEdit's scratchpad document";
    platforms = lib.platforms.darwin;
  };
}
