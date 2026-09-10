{
  lib,
  removeReferencesTo,
  runCommand,
  testers,
  iana-etc,
  mailcap,
  openssh,
  rclone,
  restic,
  tzdata,
}:
let
  supportedBackends = [
    "b2"
    "local"
    "rest"
    "s3"
  ];

  unsupportedBackends = [
    "azure"
    "gs"
    "rclone"
    "sftp"
    "swift"
  ];
in
restic.overrideAttrs (
  finalAttrs: previousAttrs: {
    ldflags = previousAttrs.ldflags ++ [
      "-s"
      "-w"
    ];

    tags = previousAttrs.tags or [ ] ++ [ "timetzdata" ];

    env = previousAttrs.env // {
      CGO_ENABLED = 0;
    };

    nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [ removeReferencesTo ];

    postConfigure = ''
      registry=$(grep -rlF 'backends.Register(local.NewFactory())' cmd internal --include='*.go')
      test "$(printf %s "$registry" | grep -c .)" -eq 1
    ''
    + lib.strings.concatMapStrings (backend: ''
      substituteInPlace "$registry" \
        --replace-fail '"github.com/restic/restic/internal/backend/${backend}"' "" \
        --replace-fail 'backends.Register(${backend}.NewFactory())' ""
    '') unsupportedBackends;

    postInstall = ''
      remove-references-to -t ${tzdata} -t ${mailcap} -t ${iana-etc} $out/bin/restic
    '';

    disallowedReferences = previousAttrs.disallowedReferences ++ [
      iana-etc
      mailcap
      openssh
      rclone
      tzdata
    ];

    passthru = previousAttrs.passthru // {
      tests =
        let
          restic' = finalAttrs.finalPackage;
        in
        {
          version = testers.testVersion {
            package = restic';
            command = "restic version";
          };

          backends = runCommand "test-restic-backends" { nativeBuildInputs = [ restic' ]; } ''
            options=$(restic options)

            for backend in ${lib.strings.concatStringsSep " " supportedBackends}; do
              if ! grep --quiet "^  $backend\." <<<"$options"; then
                echo "expected '$backend' to be supported"
                exit 1
              fi
            done

            for backend in ${lib.strings.concatStringsSep " " unsupportedBackends}; do
              if grep --quiet "^  $backend\." <<<"$options"; then
                echo "expected '$backend' to not be supported"
                exit 1
              fi

              output=$(restic --repo "$backend:" snapshots 2>&1 || true)
              if ! grep --quiet "invalid backend" <<<"$output"; then
                echo "expected '$backend:' to be rejected, but was: $output"
                exit 1
              fi
            done

            touch $out
          '';

          repository = runCommand "test-restic-repository" { nativeBuildInputs = [ restic' ]; } ''
            export HOME=$(mktemp -d)
            export RESTIC_PASSWORD=hunter2
            echo "Hello World" >data-a.txt

            restic --repo "$HOME/repo" init >/dev/null
            restic --repo "$HOME/repo" backup data-a.txt >/dev/null
            restic --repo "$HOME/repo" restore latest --target "$HOME/restored" >/dev/null
            restic --repo "$HOME/repo" check >/dev/null

            data_b=$(find "$HOME/restored" -name data-a.txt)
            if [ "$(cat data-a.txt)" != "$(cat "$data_b")" ]; then
              echo "expected: $(cat data-a.txt)"
              echo -n "actual:"
              cat "$data_b"
              exit 1
            fi

            touch $out
          '';
        };
    };
  }
)
