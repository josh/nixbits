{
  lib,
  writeShellApplication,
  darwin,
  nixbits,
}:
writeShellApplication {
  name = "scutil-sync-hostname";
  runtimeInputs = [
    nixbits.darwin.scutil
    darwin.sudo
  ];
  inheritPath = false;
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./scutil-sync-hostname.bash;
  meta = {
    description = "Set hostname to the same as the local hostname";
    platforms = lib.platforms.darwin;
  };
}
