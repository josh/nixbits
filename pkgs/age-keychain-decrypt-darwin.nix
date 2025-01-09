{
  lib,
  writeShellApplication,
  coreutils,
  age,
  age-plugin-se ? null,
  nixbits,
  age-filename ? "",
  age-dirname ? nixbits.empty-directory,
  age-basename ? "",
  age-label ? "",
  age-recipient ? "",
}:
writeShellApplication {
  name = "age-keychain-decrypt";

  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      age
      age-plugin-se
      nixbits.security-impure-darwin
    ];
    AGE_KEYCHAIN_FILENAME = age-filename;
    AGE_KEYCHAIN_DIRNAME = age-dirname;
    AGE_KEYCHAIN_BASENAME = age-basename;
    AGE_KEYCHAIN_LABEL = age-label;
    AGE_KEYCHAIN_RECIPIENT = age-recipient;
  };
  text = builtins.readFile ./age-keychain-decrypt-darwin.bash;

  meta = {
    description = "Decrypt age file using key stored in macOS Keychain";
    platforms = lib.platforms.darwin;
  };
}
