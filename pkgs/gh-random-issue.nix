{
  lib,
  stdenv,
  writeShellApplication,
  xdg-utils,
  nixbits,
}:
let
  inherit (nixbits) gh;
in
writeShellApplication {
  name = "gh-random-issue";
  runtimeInputs = [
    gh
    xdg-utils
  ] ++ (lib.lists.optionals stdenv.hostPlatform.isDarwin [ nixbits.darwin.open ]);
  inheritPath = false;
  text = builtins.readFile ./gh-random-issue.bash;

  meta = {
    description = "Open a random GitHub issue.";
    platforms = lib.platforms.all;
  };
}
