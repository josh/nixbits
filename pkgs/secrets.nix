{
  lib,
  stdenvNoCC,
  runCommand,
  coreutils,
  nixbits,
  ageIdentity ? "${nixbits.age}/bin/age-keygen",
  secretsPath ? [ ],
}:
let
  inherit (nixbits) age ensure-newline;
  toExePath = path: if lib.attrsets.isDerivation path then lib.getExe path else path;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "secrets";

  __structuredAttrs = true;

  inherit ageIdentity secretsPath;

  env.SECRETS_PATH = builtins.concatStringsSep ":" finalAttrs.secretsPath;
  env.AGE_IDENTITY_COMMAND = toExePath finalAttrs.ageIdentity;

  buildCommand = ''
    mkdir -p $out/bin
    (
      echo "#!$SHELL -e"
      echo "export PATH='${age}/bin:${ensure-newline}/bin'"
      echo "SECRETS_PATH='$SECRETS_PATH'"
      echo "AGE_IDENTITY_COMMAND='$AGE_IDENTITY_COMMAND'"
      cat ${./secrets.bash}
    ) >$out/bin/secret
    chmod +x $out/bin/secret

    mkdir -p $out/share/nix/hooks/pre-install.d
    (
      echo "#!$SHELL -e"
      echo "export PATH='${nixbits.xtrace}/bin:$out/bin'"
      for path in "''${secretsPath[@]}"; do
        for age_file in "$path"/*.age; do
          [ -e "$age_file" ] || continue
          name="$(basename "$age_file" ".age")"
          echo x -s -- secret "$name"
        done
      done
    ) >$out/share/nix/hooks/pre-install.d/secrets
    chmod +x $out/share/nix/hooks/pre-install.d/secrets
  '';

  passthru.tests =
    let
      testdata = runCommand "age-testdata" { nativeBuildInputs = [ nixbits.age ]; } ''
        mkdir $out
        age-keygen >$out/key.txt
        age-keygen -y $out/key.txt >$out/recipient.txt
        echo bar | age --encrypt --recipients-file $out/recipient.txt >$out/FOO.age
      '';
      secrets = finalAttrs.finalPackage.overrideAttrs {
        secretsPath = [ testdata ];
        ageIdentity = "${coreutils}/bin/cat ${testdata}/key.txt";
      };
    in
    {
      decrypt = runCommand "decrypt" { nativeBuildInputs = [ secrets ]; } ''
        if [ "$(secret FOO)" != "bar" ]; then
          echo "error: secret FOO not decrypted" >&2
          exit 1
        fi
        touch $out
      '';
    };

  meta = {
    description = "Decrypt secret using age identity";
    platforms = lib.platforms.all;
    mainProgram = "secret";
  };
})
