{
  lib,
  writeShellApplication,
  which,
  darwin,
  nixbits,
}:
writeShellApplication {
  name = "tmutil-exclude-volume";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      which
      darwin.sudo
      nixbits.darwin.tmutil
    ];
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./tmutil-exclude-volume.bash;
  meta = {
    description = "Exclude a volume from Time Machine";
    platforms = lib.platforms.darwin;
  };
}
