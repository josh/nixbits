{
  lib,
  writeShellApplication,
  jq,
  nix,
}:
writeShellApplication {
  name = "nix-profile-nixpkgs-uri";
  runtimeInputs = [
    jq
    nix
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-profile-nixpkgs-uri.bash;

  meta = {
    description = "Print the flake URI of the profile's nixpkgs";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
