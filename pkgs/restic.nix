{
  stdenvNoCC,
  makeWrapper,
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
stdenvNoCC.mkDerivation (_finalAttrs: {
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

  meta = {
    inherit (restic.meta) description platforms;
    mainProgram = "restic";
  };
})
