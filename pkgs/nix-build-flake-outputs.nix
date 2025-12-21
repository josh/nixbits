{
  lib,
  writeShellApplication,
  nix,
  nixbits,
}:
writeShellApplication {
  name = "nix-build-flake-outputs";
  runtimeInputs = [
    nix
  ];
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  inheritPath = false;
  text = builtins.readFile ./nix-build-flake-outputs.bash;
  meta = {
    description = "Build all flake outputs as a nix package";
    platforms = lib.platforms.all;
  };
}
