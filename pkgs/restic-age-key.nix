{ nur, nixbits }:
let
  age = nixbits.age.override {
    seSupport = true;
    tpmSupport = true;
    yubikeySupport = true;
  };
in
nur.repos.josh.restic-age-key.override {
  inherit age;
}
