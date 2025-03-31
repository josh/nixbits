{
  lib,
  writeShellApplication,
  nix,
  jq,
}:
writeShellApplication {
  name = "nix-profile-nixpkgs-uri";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      nix
      jq
    ];
  };
  text = builtins.readFile ./nix-profile-nixpkgs-uri.bash;
}
