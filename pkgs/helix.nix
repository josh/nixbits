{
  lib,
  stdenvNoCC,
  writers,
  lndir,
  makeWrapper,
  helix,
  helixConfig ? { },
}:
let
  helixConfigFile = writers.writeTOML "helix-config.toml" helixConfig;
in
stdenvNoCC.mkDerivation {
  inherit (helix) pname version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    lndir
    makeWrapper
  ];

  makeWrapperArgs = [
    "--add-flags"
    "--config ${helixConfigFile}"
  ];

  buildCommand = ''
    mkdir -p $out
    lndir -silent ${helix} $out

    rm $out/bin/hx
    makeWrapper ${lib.getExe helix} $out/bin/hx "''${makeWrapperArgs[@]}"
  '';

  meta = {
    inherit (helix.meta) description license;
    mainProgram = "hx";
  };
}
