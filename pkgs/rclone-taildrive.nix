{
  lib,
  stdenvNoCC,
  makeWrapper,
  runCommand,
  rclone,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  name = "rclone-taildrive";
  inherit (rclone) version;

  nativeBuildInputs = [ makeWrapper ];

  makeWrapperArgs = [
    "--set-default"
    "RCLONE_CONFIG"
    ""

    "--set"
    "RCLONE_CONFIG_TAILDRIVE_TYPE"
    "webdav"

    "--set"
    "RCLONE_CONFIG_TAILDRIVE_URL"
    "http://100.100.100.100:8080"

    "--set"
    "RCLONE_CONFIG_TAILDRIVE_VENDOR"
    "other"
  ];

  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${lib.getExe rclone} $out/bin/rclone "''${makeWrapperArgs[@]}"
  '';

  meta = {
    inherit (rclone.meta)
      homepage
      description
      license
      platforms
      ;
    mainProgram = "rclone";
  };

  passthru.tests =
    let
      rclone = finalAttrs.finalPackage;
    in
    {
      listremotes = runCommand "test-rclone-listremotes" { nativeBuildInputs = [ rclone ]; } ''
        if rclone listremotes | grep -q "taildrive:"; then
          touch $out
        else
          echo "rclone listremotes missing taildrive" >&2
          exit 1
        fi
      '';
    };
})
