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
}
