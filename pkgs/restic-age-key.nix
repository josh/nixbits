{ nur, nixbits }:
let
  age = nixbits.age-old.override {
    seSupport = true;
    tpmSupport = true;
    yubikeySupport = true;
  };
in
nur.repos.josh.restic-age-key.override {
  inherit age;
}
