{
  stdenvNoCC,
  makeWrapper,
  lndir,
  less,
}:
stdenvNoCC.mkDerivation {
  name = "less";

  __structuredAttrs = true;

  nativeBuildInputs = [ makeWrapper ];
  makeWrapperArgs = [
    "--set"
    "LESSHISTFILE"
    "-"
  ];

  buildCommand = ''
    mkdir $out
    ${lndir}/bin/lndir -silent ${less} $out

    rm $out/bin/less
    makeWrapper ${less}/bin/less $out/bin/less "''${makeWrapperArgs[@]}"
  '';

  meta.mainProgram = "less";
}
