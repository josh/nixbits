{
  lib,
  writeShellApplication,
  which,
  nixbits,
}:
writeShellApplication {
  name = "tmutil-exclude-volume";
  runtimeInputs = [
    which
    nixbits.darwin.sudo
    nixbits.darwin.tmutil
  ];
  inheritPath = false;
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./tmutil-exclude-volume.bash;
  meta = {
    description = "Exclude a volume from Time Machine";
    platforms = lib.platforms.darwin;
  };
}
