final: prev:
let
  inherit (final) lib;
  prev' = lib.attrsets.mapAttrs' (name: lib.attrsets.nameValuePair "${name}'") prev;
  callPackage = lib.callPackageWith (final // prev');
  pkgs = lib.filesystem.packagesFromDirectoryRecursive {
    inherit callPackage;
    directory = ./pkgs;
  };
in
{
  nixbits = pkgs;
}
