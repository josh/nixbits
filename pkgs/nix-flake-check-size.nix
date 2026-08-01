{
  lib,
  writeShellApplication,
  coreutils,
  nix,
  jq,
}:
writeShellApplication {
  name = "nix-flake-check-size";
  runtimeInputs = [
    coreutils
    jq
    nix
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-flake-check-size.bash;
  meta = {
    description = "Check NAR size of flake checks";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
