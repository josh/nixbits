{
  lib,
  stdenvNoCC,
  gnutar,
}:
stdenvNoCC.mkDerivation {
  pname = "gtar";
  inherit (gnutar) version;

  __structuredAttrs = true;

  buildCommand = ''
    mkdir -p $out/bin
    ln -s ${lib.getExe gnutar} $out/bin/gtar
  '';

  meta = {
    description = "GNU tar alias";
    longDescription = ''
      Alias gtar to gnutar for GitHub Actions workflows.
      <https://github.com/actions/upload-pages-artifact/blob/2d163be/action.yml#L41>
    '';
    mainProgram = "gtar";
    platforms = lib.platforms.all;
  };
}
