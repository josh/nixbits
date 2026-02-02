{ callPackage, nur }:
let
  pkg = callPackage ./sops.nix {
    inherit (nur.repos.josh) age-plugin-se;
    age-plugin-tpm = nur.repos.josh.age-plugin-tpm-old;
  };
in
pkg.overrideAttrs (
  _finalAttrs: prevAttrs: {
    pname = "${prevAttrs.pname}-old";
  }
)
