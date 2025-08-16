{
  lib,
  writeShellApplication,
  coreutils,
  moreutils,
  hostname,
  nixbits,
}:
writeShellApplication {
  name = "fish-history-sync";
  runtimeInputs = [
    coreutils
    moreutils
    hostname
    nixbits.fish-history-merge
  ];
  inheritPath = false;
  text = builtins.readFile ./fish-history-sync.bash;
  meta = {
    description = "Sync fish history with iCloud Drive";
    platforms = lib.platforms.darwin;
  };
}
