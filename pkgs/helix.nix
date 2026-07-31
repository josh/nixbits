{
  lib,
  pkgs,
  stdenvNoCC,
  writers,
  makeWrapper,
  lndir,
  evil-helix,
  helix ? evil-helix,
  helixConfig ? { },
}:
let
  helix' = if helix == pkgs.helix then evil-helix else helix;
  helixConfigFile = writers.writeTOML "helix-config.toml" helixConfig;
in
stdenvNoCC.mkDerivation {
  inherit (helix') pname version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
    lndir
  ];

  makeWrapperArgs = [
    "--add-flags"
    "--config ${helixConfigFile}"
  ];

  buildCommand = ''
    mkdir -p $out
    lndir -silent ${helix'} $out

    rm $out/bin/hx
    makeWrapper ${lib.getExe helix'} $out/bin/hx "''${makeWrapperArgs[@]}"
  '';

  meta = {
    mainProgram = "hx";
    inherit (helix'.meta) description license platforms;
  };
}
