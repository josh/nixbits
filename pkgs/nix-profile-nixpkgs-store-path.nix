{
  writeShellApplication,
  nix,
  jq,
  nixbits,
}:
writeShellApplication {
  name = "nix-profile-nixpkgs-store-path";
  runtimeInputs = [
    nix
    jq
    nixbits.nix-profile-nixpkgs-uri
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-profile-nixpkgs-store-path.bash;

  meta.description = "Print the store path of the profile's nixpkgs";
}
