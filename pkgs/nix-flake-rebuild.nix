{
  lib,
  writeShellApplication,
  coreutils,
  jq,
  nix,
  nixbits,
}:
writeShellApplication {
  name = "nix-flake-rebuild";
  runtimeInputs = [
    coreutils
    jq
    nix
    nixbits.term-status
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-flake-rebuild.bash;

  meta = {
    description = "Rebuild all packages in current nix flake";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
