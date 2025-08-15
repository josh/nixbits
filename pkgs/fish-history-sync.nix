{
  lib,
  writeShellApplication,
  coreutils,
  hostname,
}:
writeShellApplication {
  name = "fish-history-sync";
  runtimeInputs = [
    coreutils
    hostname
  ];
  inheritPath = false;
  text = builtins.readFile ./fish-history-sync.bash;
  meta = {
    description = "Sync fish history with iCloud Drive";
    platforms = lib.platforms.darwin;
  };
}
