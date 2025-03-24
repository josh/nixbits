{
  lib,
  writeTextFile,
  writeShellApplication,
  nixbits,
}:
let
  scpt = writeTextFile {
    name = "bbedit-scratchpad.scpt";
    text = ''
      tell application "BBEdit"
        activate
        open scratchpad document
        set the index of the window of scratchpad document to 1
      end tell
    '';
  };
in
writeShellApplication {
  name = "bbedit-scratchpad";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [ nixbits.darwin.osascript ];
  };
  text = ''
    osascript <${scpt}
  '';
  meta = {
    description = "Open BBEdit's scratchpad document";
    platforms = lib.platforms.darwin;
  };
}
