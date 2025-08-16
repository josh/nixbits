{
  lib,
  writeShellApplication,
  coreutils,
  moreutils,
  hostname,
  nur,
  nixbits,
}:
writeShellApplication {
  name = "fish-history-sync";
  runtimeInputs = [
    coreutils
    moreutils
    hostname
    nur.repos.josh.histutils
    nixbits.fish-history-merge
  ];
  inheritPath = false;
  text = builtins.readFile ./fish-history-sync.bash;
  meta = {
    description = "Sync fish history with iCloud Drive";
    platforms = lib.platforms.darwin;
  };
}
