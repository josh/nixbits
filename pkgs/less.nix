{
  stdenvNoCC,
  lndir,
  makeWrapper,
  less,
}:
stdenvNoCC.mkDerivation {
  pname = "less";
  inherit (less) version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    lndir
    makeWrapper
  ];
  makeWrapperArgs = [
    "--set"
    "LESSHISTFILE"
    "-"
  ];

  buildCommand = ''
    mkdir $out
    lndir -silent ${less} $out

    rm $out/bin/less
    makeWrapper ${less}/bin/less $out/bin/less "''${makeWrapperArgs[@]}"
  '';

  meta = {
    description = "less with the history file disabled";
    mainProgram = "less";
  };
}
