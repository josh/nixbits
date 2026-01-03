{
  callPackage,
  stdenv,
}:
let
  inherit (stdenv.hostPlatform) system;
  nixpkgs-legacy = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/f560ccec6b1116b22e6ed15f4c510997d99d5852.tar.gz";
    sha256 = "sha256-BASnpCLodmgiVn0M1MU2Pqyoz0aHwar/0qLkp7CjvSQ=";
  };
  pkgs-legacy = import nixpkgs-legacy { inherit system; };

  pkg = callPackage ./age.nix {
    age-plugin-se' = pkgs-legacy.age-plugin-se;
    inherit (pkgs-legacy) age-plugin-tpm;
    inherit (pkgs-legacy) age-plugin-yubikey;
  };
in
pkg.overrideAttrs (
  _finalAttrs: prevAttrs: {
    pname = "${prevAttrs.pname}-legacy";
  }
)
