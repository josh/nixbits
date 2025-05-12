{
  lib,
  writeShellApplication,
  runCommand,
  coreutils,
  jq,
  openssl,
  restic,
  nur,
  nixbits,
}:
let
  age = nixbits.age.override {
    seSupport = true;
    tpmSupport = true;
  };
  restic-age-init = writeShellApplication {
    name = "restic-age-init";
    runtimeInputs = [
      age
      coreutils
      jq
      nur.repos.josh.restic-age-key
      openssl
      restic
    ];
    inheritPath = false;
    runtimeEnv = {
      XTRACE_PATH = nixbits.xtrace;
    };
    text = builtins.readFile ./restic-age-init.bash;
    meta = {
      description = "Initialize restic repository with age key";
      platforms = lib.platforms.all;
    };
  };
in
restic-age-init.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        restic-age-init = finalAttrs.finalPackage;
      in
      {
        init-identity-file =
          runCommand "test-init-identity-file"
            {
              nativeBuildInputs = [
                age
                restic-age-init
              ];
            }
            ''
              age-keygen --output key.txt
              restic-age-init --repo "$TMPDIR/restic-repo" \
                --identity-file key.txt
              touch $out
            '';

        init-identity-command =
          runCommand "test-init-identity-command"
            {
              nativeBuildInputs = [
                age
                restic-age-init
              ];
            }
            ''
              age-keygen --output key.txt
              restic-age-init --repo "$TMPDIR/restic-repo" \
                --identity-command 'cat key.txt'
              touch $out
            '';

        init-from-repo =
          runCommand "test-init-from-repo"
            {
              nativeBuildInputs = [
                age
                restic
                restic-age-init
              ];
            }
            ''
              echo "secret" >password.txt
              restic init --repo "$TMPDIR/restic-repo-a" --password-file "password.txt"
              age-keygen --output key.txt
              restic-age-init --repo "$TMPDIR/restic-repo-b" \
                --identity-file key.txt \
                --from-repo "$TMPDIR/restic-repo-a" \
                --from-password-file "password.txt" \
                --copy-chunker-params
              touch $out
            '';
      };
  }
)
