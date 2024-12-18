{
  lib,
  stdenv,
  makeWrapper,
  runCommand,
  rclone,
}:
stdenv.mkDerivation (finalAttrs: {
  name = "rclone-taildrive";
  inherit (rclone) version;

  nativeBuildInputs = [ makeWrapper ];

  buildCommand = ''
    mkdir -p $out/bin
    ln -s ${lib.getExe rclone} $out/bin/rclone

    wrapProgram $out/bin/rclone \
      --set-default RCLONE_CONFIG "" \
      --set RCLONE_CONFIG_TAILDRIVE_TYPE webdav \
      --set RCLONE_CONFIG_TAILDRIVE_URL http://100.100.100.100:8080 \
      --set RCLONE_CONFIG_TAILDRIVE_VENDOR other
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
