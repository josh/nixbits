{
  lib,
  writeShellApplication,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "zsh-history-sync";
  runtimeInputs = [
    coreutils
    nixbits.zsh-history-merge
  ];
  inheritPath = false;
  text = builtins.readFile ./zsh-history-sync.bash;
  meta = {
    description = "Sync zsh history with iCloud Drive";
    platforms = lib.platforms.darwin;
  };
}
