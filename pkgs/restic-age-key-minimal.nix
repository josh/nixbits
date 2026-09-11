{
  lib,
  runCommand,
  testers,
  rclone,
  nur,
}:
nur.repos.josh.restic-age-key.overrideAttrs (
  finalAttrs: previousAttrs: {
    ldflags = builtins.filter (
      flag: !(lib.strings.hasPrefix "-X main.RcloneProgram=" flag)
    ) previousAttrs.ldflags;

    disallowedReferences = previousAttrs.disallowedReferences ++ [ rclone ];

    passthru = previousAttrs.passthru // {
      tests =
        let
          restic-age-key = finalAttrs.finalPackage;
        in
        {
          version = testers.testVersion {
            package = restic-age-key;
          };

          help = runCommand "test-restic-age-key-help" { nativeBuildInputs = [ restic-age-key ]; } ''
            restic-age-key --help
            touch $out
          '';

          age-path = runCommand "test-restic-age-key-age-path" { nativeBuildInputs = [ restic-age-key ]; } ''
            help=$(restic-age-key --help)
            if ! grep --quiet --extended-regexp 'age-program.*\(default "/nix/store/.*/bin/age"\)' <<<"$help"; then
              echo "expected --age-program to default to a store path"
              exit 1
            fi
            touch $out
          '';

          rclone-path =
            runCommand "test-restic-age-key-rclone-path" { nativeBuildInputs = [ restic-age-key ]; }
              ''
                help=$(restic-age-key --help)
                if ! grep --quiet --extended-regexp 'rclone-program.*\(default "rclone"\)' <<<"$help"; then
                  echo "expected --rclone-program to default to rclone from PATH"
                  exit 1
                fi
                if grep --quiet --fixed-strings '${lib.getExe rclone}' <<<"$help"; then
                  echo "expected ${lib.getExe rclone} to not be baked in"
                  exit 1
                fi
                touch $out
              '';
        };
    };
  }
)
