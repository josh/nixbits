{
  lib,
  writeShellApplication,
  coreutils,
  moreutils,
  nixbits,
}:
writeShellApplication {
  name = "zsh-session-prune";
  runtimeInputs = [
    coreutils
    moreutils
    nixbits.zsh-history-merge
  ];
  inheritPath = false;
  text = builtins.readFile ./zsh-session-prune.bash;
  meta = {
    description = "Prune macOS zsh sessions directory";
    platforms = lib.platforms.darwin;
  };
}
