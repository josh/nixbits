{
  lib,
  writeShellApplication,
  coreutils,
  moreutils,
  hostname,
  nur,
}:
writeShellApplication {
  name = "zsh-history-sync";
  runtimeInputs = [
    coreutils
    moreutils
    hostname
    nur.repos.josh.histutils
  ];
  inheritPath = false;
  text = builtins.readFile ./zsh-history-sync.bash;
  meta = {
    description = "Sync zsh history with iCloud Drive";
    platforms = lib.platforms.darwin;
  };
}
