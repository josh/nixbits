{
  callPackage,
  nur,
  seSupport ? true,
  tpmSupport ? true,
  yubikeySupport ? true,
}:
let
  pkg = callPackage ./age.nix {
    inherit (nur.repos.josh) age-plugin-se;
    age-plugin-tpm = nur.repos.josh.age-plugin-tpm-old;
    inherit seSupport tpmSupport yubikeySupport;
  };
in
pkg.overrideAttrs (
  _finalAttrs: prevAttrs: {
    pname = "${prevAttrs.pname}-old";
  }
)
