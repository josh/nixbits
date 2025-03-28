{
  stdenvNoCC,
  makeWrapper,
  runCommand,
  lndir,
  rclone,
  restic,
  nur,
  nixbits,
}:
let
  restic-age-key = nur.repos.josh.restic-age-key.override {
    age = nixbits.age-with-se-tpm;
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "restic";
  inherit (restic) version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
    lndir
  ];

  makeWrapperArgs =
    [
      "--prefix"
      "PATH"
      ":"
      "${rclone}/bin"
    ]
    ++ [
      "--set-default"
      "RCLONE_CONFIG"
      ""
    ]
    ++ [
      "--set"
      "RCLONE_CONFIG_TAILDRIVE_TYPE"
      "webdav"
    ]
    ++ [
      "--set"
      "RCLONE_CONFIG_TAILDRIVE_URL"
      "http://100.100.100.100:8080"
    ]
    ++ [
      "--set"
      "RCLONE_CONFIG_TAILDRIVE_VENDOR"
      "other"
    ];

  buildCommand = ''
    mkdir -p $out
    lndir -silent ${restic} $out
    lndir -silent ${restic-age-key} $out

    rm $out/bin/restic $out/bin/restic-age-key
    makeWrapper ${restic}/bin/.restic-wrapped $out/bin/restic --inherit-argv0 "''${makeWrapperArgs[@]}"
    makeWrapper ${restic-age-key}/bin/restic-age-key $out/bin/restic-age-key "''${makeWrapperArgs[@]}"
  '';

  passthru.tests =
    let
      restic = finalAttrs.finalPackage;
    in
    {
      help = runCommand "test-restic-help" { nativeBuildInputs = [ restic ]; } ''
        restic --help
        touch $out
      '';

      rclone-taildrive = runCommand "test-rclone-taildrive" { nativeBuildInputs = [ restic ]; } ''
        restic --repo rclone:taildrive:foo cat config 1>out.txt 2>&1 || true
        echo "-- out.txt --"
        cat out.txt
        echo "-- out.txt --"
        if grep 'Failed to create file system for "taildrive:foo"' out.txt; then
          echo "rclone:taildrive remote not configured"
          exit 1
        fi
        if grep 'Config file "/homeless-shelter/.rclone.conf" not found' out.txt; then
          echo "rclone expecting config file"
          exit 1
        fi
        touch $out
      '';
    };

  meta = {
    inherit (restic.meta) description platforms;
    mainProgram = "restic";
  };
})
