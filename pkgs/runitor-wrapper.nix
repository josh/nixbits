{
  stdenvNoCC,
  lndir,
  makeWrapper,
  runitor,
}:
stdenvNoCC.mkDerivation {
  __structuredAttrs = true;

  pname = "runitor";
  inherit (runitor) version;

  nativeBuildInputs = [
    lndir
    makeWrapper
  ];
  makeWrapperArgs = [ ];

  buildCommand = ''
    mkdir $out
    lndir -silent ${runitor} $out

    rm $out/bin/runitor
    makeWrapper ${runitor}/bin/runitor $out/bin/runitor "''${makeWrapperArgs[@]}"
  '';

  inherit (runitor) meta;
}
