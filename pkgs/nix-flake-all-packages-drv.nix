{
  lib,
  system,
  writeShellApplication,
  nix,
}:
let
  nix-flake-all-packages-drv = builtins.path {
    path = ./nix-flake-all-packages-drv.txt;
    name = "nix-flake-all-packages-drv.txt";
    recursive = false;
  };
in
writeShellApplication {
  name = "nix-flake-all-packages-drv";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [ nix ];
    SYSTEM = system;
    NIX_EXPR_FILE = nix-flake-all-packages-drv;
  };
  text = builtins.readFile ./nix-flake-all-packages-drv.bash;
  meta = {
    description = "Build nix derivation for all packages in current nix flake";
    platforms = lib.platforms.all;
  };
}
