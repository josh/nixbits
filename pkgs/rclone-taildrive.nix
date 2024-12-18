{
  lib,
  stdenv,
  makeWrapper,
  runCommand,
  rclone,
  nixbits,
}:
stdenv.mkDerivation (finalAttrs: {
  name = "rclone-taildrive";
  inherit (rclone) version;

  nativeBuildInputs = [ makeWrapper ];

  buildCommand = ''
    mkdir -p $out/bin
    ln -s ${lib.getExe rclone} $out/bin/rclone
    wrapProgram $out/bin/rclone --set RCLONE_CONFIG ${nixbits.rclone-taildrive-config}
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
