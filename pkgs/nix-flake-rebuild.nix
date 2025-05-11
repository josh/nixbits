{
  writeShellApplication,
  coreutils,
  nix,
  jq,
}:
writeShellApplication {
  name = "nix-flake-rebuild";
  runtimeInputs = [
    coreutils
    nix
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-flake-rebuild.bash;

  meta.description = "Rebuild all packages in current nix flake";
}
