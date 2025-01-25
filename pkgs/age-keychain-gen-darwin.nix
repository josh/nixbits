{
  lib,
  writeShellApplication,
  coreutils,
  age,
  age-plugin-se ? null,
  nixbits,
}:
writeShellApplication {
  name = "age-keychain-gen";

  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      age
      age-plugin-se
      nixbits.darwin.security
    ];
  };
  text = builtins.readFile ./age-keychain-gen-darwin.bash;

  meta = {
    description = "Generate age key and store in macOS Keychain";
    platforms = lib.platforms.darwin;
  };
}
