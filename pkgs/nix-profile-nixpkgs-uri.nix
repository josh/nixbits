{
  writeShellApplication,
  nix,
  jq,
}:
writeShellApplication {
  name = "nix-profile-nixpkgs-uri";
  runtimeInputs = [
    nix
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-profile-nixpkgs-uri.bash;

  meta.description = "Print the flake URI of the profile's nixpkgs";
}
