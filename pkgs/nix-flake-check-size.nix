{
  lib,
  writeShellApplication,
  coreutils,
  nix,
  jq,
}:
writeShellApplication {
  name = "nix-flake-check-size";
  runtimeInputs = [
    coreutils
    nix
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-flake-check-size.bash;
  meta = {
    description = "Check NAR size of flake checks";
    platforms = lib.platforms.all;
  };
}
