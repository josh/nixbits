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
  inheritPath = false;
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./nix-build-flake-outputs.bash;
  meta = {
    description = "Build all flake outputs as a nix package";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
