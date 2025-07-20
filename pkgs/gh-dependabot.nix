{
  lib,
  stdenv,
  writeShellApplication,
  coreutils,
  findutils,
  jq,
  nixbits,
}:
let
  inherit (nixbits) gh;
in
writeShellApplication {
  name = "gh-dependabot";
  runtimeInputs = [
    coreutils
    findutils
    gh
    jq
  ]
  ++ (lib.lists.optional stdenv.hostPlatform.isDarwin nixbits.darwin.open);
  inheritPath = false;
  text = builtins.readFile ./gh-dependabot.bash;
  meta = {
    description = "Open GitHub Insights -> Dependency graph -> Dependabot page";
    platforms = lib.platforms.all;
  };
}
