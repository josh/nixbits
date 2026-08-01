{
  lib,
  stdenv,
  writeShellApplication,
  findutils,
  jq,
  xdg-utils,
  nixbits,
}:
let
  inherit (nixbits) gh;
in
writeShellApplication {
  name = "gh-dependabot";
  runtimeInputs = [
    findutils
    gh
    jq
    xdg-utils
  ]
  ++ (lib.lists.optional stdenv.hostPlatform.isDarwin nixbits.darwin.open);
  inheritPath = false;
  text = builtins.readFile ./gh-dependabot.bash;
  meta = {
    description = "Open GitHub Insights -> Dependency graph -> Dependabot page";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
