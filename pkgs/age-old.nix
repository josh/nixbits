{ callPackage, nur }:
let
  pkg = callPackage ./age.nix {
    age-plugin-se = nur.repos.josh.age-plugin-se-old;
    age-plugin-tpm = nur.repos.josh.age-plugin-tpm-old;
  };
in
pkg.overrideAttrs (
  _finalAttrs: prevAttrs: {
    pname = "${prevAttrs.pname}-old";
  }
)
