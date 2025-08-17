{
  lib,
  writeShellApplication,
  coreutils,
  moreutils,
  nur,
}:
writeShellApplication {
  name = "zsh-session-prune";
  runtimeInputs = [
    coreutils
    moreutils
    nur.repos.josh.histutils
  ];
  inheritPath = false;
  text = builtins.readFile ./zsh-session-prune.bash;
  meta = {
    description = "Prune macOS zsh sessions directory";
    platforms = lib.platforms.darwin;
  };
}
