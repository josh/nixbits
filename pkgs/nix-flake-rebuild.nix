{
  lib,
  writeShellApplication,
  coreutils,
  nix,
  jq,
}:
writeShellApplication {
  name = "nix-flake-rebuild";
  runtimeInputs = [
    coreutils
    jq
    nix
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-flake-rebuild.bash;

  meta = {
    description = "Rebuild all packages in current nix flake";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
