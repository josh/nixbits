{
  lib,
  writeShellApplication,
  nix,
  jq,
  nixbits,
}:
writeShellApplication {
  name = "nix-profile-nixpkgs-store-path";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      nix
      jq
      nixbits.nix-profile-nixpkgs-uri
    ];
  };
  text = builtins.readFile ./nix-profile-nixpkgs-store-path.bash;
}
