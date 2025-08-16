{
  lib,
  writeShellApplication,
  coreutils,
  moreutils,
  hostname,
  nixbits,
}:
writeShellApplication {
  name = "zsh-history-sync";
  runtimeInputs = [
    coreutils
    moreutils
    hostname
    nixbits.zsh-history-merge
  ];
  inheritPath = false;
  text = builtins.readFile ./zsh-history-sync.bash;
  meta = {
    description = "Sync zsh history with iCloud Drive";
    platforms = lib.platforms.darwin;
  };
}
