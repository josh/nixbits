{
  lib,
  writeShellApplication,
  nixbits,
}:
let
  inherit (nixbits) gh;
in
writeShellApplication {
  name = "gh-subscriptions-prune";
  runtimeInputs = [
    gh
  ];
  inheritPath = false;
  text = builtins.readFile ./gh-subscriptions-prune.bash;
  meta = {
    description = "Unsubscribe from issue/PR notifications in my own repos";
    platforms = lib.platforms.all;
  };
}
