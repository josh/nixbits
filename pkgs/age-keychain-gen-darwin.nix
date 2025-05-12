{
  lib,
  writeShellApplication,
  coreutils,
  nixbits,
}:
let
  age = nixbits.age.override { seSupport = true; };
in
writeShellApplication {
  name = "age-keychain-gen";

  runtimeInputs = [
    coreutils
    age
    nixbits.darwin.security
  ];
  inheritPath = false;
  text = builtins.readFile ./age-keychain-gen-darwin.bash;

  meta = {
    description = "Generate age key and store in macOS Keychain";
    platforms = lib.platforms.darwin;
  };
}
