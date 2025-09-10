{
  lib,
  writeShellApplication,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "scutil-set-hostname";
  runtimeInputs = [
    coreutils
    nixbits.darwin.dscacheutil
    nixbits.darwin.scutil
  ];
  inheritPath = false;
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./scutil-set-hostname.bash;
  meta = {
    description = "Set macOS computer name, bonjour name and unix hostname";
    platforms = lib.platforms.darwin;
  };
}
