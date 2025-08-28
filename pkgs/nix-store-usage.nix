{
  lib,
  stdenv,
  writeShellApplication,
  coreutils,
  gawk,
  jq,
  nix,
  nixbits,
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
  runtimeEnv = {
    DF_EXE = if stdenv.isDarwin then "${nixbits.darwin.df}/bin/df" else "${coreutils}/bin/df";
  };
  text = builtins.readFile ./nix-store-usage.bash;
  meta = {
    description = "Compute nix store usage";
    platforms = lib.platforms.all;
  };
}
