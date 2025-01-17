{
  lib,
  writeShellApplication,
  coreutils,
  age,
  age-plugin-se ? null,
  nixbits,
  name ? "age-keychain-decrypt",
  age-filename ? "",
  age-dirname ? nixbits.empty-directory,
  age-basename ? "",
  age-label ? "",
  age-recipient ? "",
}:
writeShellApplication {
  inherit name;

  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      age
      age-plugin-se
      nixbits.darwin.security
    ];
    AGE_KEYCHAIN_FILENAME = age-filename;
    AGE_KEYCHAIN_DIRNAME = age-dirname;
    AGE_KEYCHAIN_BASENAME = age-basename;
    AGE_KEYCHAIN_LABEL = age-label;
    AGE_KEYCHAIN_RECIPIENT = age-recipient;
  };
  text = builtins.readFile ./age-keychain-decrypt-darwin.bash;

  derivationArgs = {
    preCheck = ''
      if [ -n "${age-filename}" ] && [ ! -f "${age-filename}" ]; then
        echo "error: '${age-filename}' not a file" >&2
        exit 1
      fi

      if [ -n "${age-dirname}" ] && [ ! -d "${age-dirname}" ]; then
        echo "error: '${age-dirname}' not a directory" >&2
        exit 1
      fi

      if [ -n "${age-basename}" ] && [ ! -f "${age-dirname}/${age-basename}" ]; then
        echo "error: '${age-dirname}/${age-basename}' not a file" >&2
        exit 1
      fi
    '';
  };

  meta = {
    description = "Decrypt age file using key stored in macOS Keychain";
    platforms = lib.platforms.darwin;
  };
}
