{
  lib,
  writeShellApplication,
  nixbits,
  neovimPackage ? nixbits.neovim,
}:
let
  neorex = nixbits.neorex.override { inherit neovimPackage; };
in
if neorex.meta.available then
  writeShellApplication {
    name = "nvim";
    runtimeEnv = {
      NVIM_BIN = lib.getExe' neovimPackage "nvim";
      NEOREX_BIN = lib.getExe neorex;
    };
    text = builtins.readFile ./neovim-launcher.bash;
  }
else
  neovimPackage
