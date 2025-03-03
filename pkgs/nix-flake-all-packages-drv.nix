{
  lib,
  system,
  writeShellApplication,
  nix,
}:
writeShellApplication {
  name = "nix-flake-all-packages-drv";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [ nix ];
    SYSTEM = system;
    NIX_EXPR_FILE = "${./nix-flake-all-packages-drv.txt}";
  };
  text = builtins.readFile ./nix-flake-all-packages-drv.bash;
  meta = {
    description = "Build nix derivation for all packages in current nix flake";
    platforms = lib.platforms.all;
  };
}
