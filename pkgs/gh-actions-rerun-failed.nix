{
  lib,
  writeShellApplication,
  nixbits,
}:
let
  inherit (nixbits) gh;
in
writeShellApplication {
  name = "gh-actions-rerun-failed";
  runtimeInputs = [
    gh
  ];
  inheritPath = false;
  text = builtins.readFile ./gh-actions-rerun-failed.bash;
  meta = {
    description = "Re-run any failed GitHub Actions jobs on my repos";
    platforms = lib.platforms.all;
  };
}
