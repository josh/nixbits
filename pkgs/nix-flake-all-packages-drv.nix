{
  lib,
  stdenv,
  writeShellApplication,
  nix,
}:
writeShellApplication {
  name = "nix-flake-all-packages-drv";
  runtimeInputs = [ nix ];
  inheritPath = false;
  runtimeEnv = {
    SYSTEM = stdenv.hostPlatform.system;
    NIX_EXPR_FILE = "${./nix-flake-all-packages-drv.txt}";
  };
  text = builtins.readFile ./nix-flake-all-packages-drv.bash;
  meta = {
    description = "Build nix derivation for all packages in current nix flake";
    platforms = lib.platforms.all;
  };
}
