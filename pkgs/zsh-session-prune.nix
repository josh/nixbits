{
  lib,
  writeShellApplication,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "zsh-session-prune";
  runtimeInputs = [
    coreutils
    nixbits.zsh-history-merge
  ];
  inheritPath = false;
  text = builtins.readFile ./zsh-session-prune.bash;
  meta = {
    description = "Prune macOS zsh sessions directory";
    platforms = lib.platforms.darwin;
  };
}
