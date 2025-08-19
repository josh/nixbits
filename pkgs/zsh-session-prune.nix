{
  lib,
  writeShellApplication,
  coreutils,
  nur,
}:
writeShellApplication {
  name = "zsh-session-prune";
  runtimeInputs = [
    coreutils
    nur.repos.josh.histutils
  ];
  inheritPath = false;
  text = builtins.readFile ./zsh-session-prune.bash;
  meta = {
    description = "Prune macOS zsh sessions directory";
    platforms = lib.platforms.darwin;
  };
}
