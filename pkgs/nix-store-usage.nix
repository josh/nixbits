{
  lib,
  writeShellApplication,
  coreutils,
  gawk,
  jq,
  nix,
}:
writeShellApplication {
  name = "nix-store-usage";
  runtimeInputs = [
    coreutils
    gawk
    jq
    nix
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-store-usage.bash;
  meta = {
    description = "Compute nix store usage";
    platforms = lib.platforms.all;
  };
}
