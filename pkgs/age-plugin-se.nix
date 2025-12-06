# Work around swift compiler build failure on linux
# https://github.com/josh/nixpkgs/issues/14
{
  lib,
  stdenv,
  age-plugin-se,
}:
let
  inherit (stdenv.hostPlatform) system;
  nixpkgs = builtins.getFlake "github:NixOS/nixpkgs/01b6809f7f9d1183a2b3e081f0a1e6f8f415cb09";
  pkgs = nixpkgs.legacyPackages.${system};
in
if lib.strings.hasSuffix "-linux" system then pkgs.age-plugin-se else age-plugin-se
