{
  lib,
  writeShellApplication,
  coreutils,
  hostname,
  nur,
}:
writeShellApplication {
  name = "zsh-history-sync";
  runtimeInputs = [
    coreutils
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
