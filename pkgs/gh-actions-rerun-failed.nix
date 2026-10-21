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
    nixbits.term-status
  ];
  inheritPath = false;
  text = builtins.readFile ./gh-actions-rerun-failed.bash;
  meta = {
    description = "Re-run failed GitHub Actions jobs across owned repositories";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
