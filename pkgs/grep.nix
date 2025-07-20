{
  stdenvNoCC,
  makeWrapper,
  lndir,
  gnugrep,
}:
stdenvNoCC.mkDerivation {
  name = "grep";

  __structuredAttrs = true;

  nativeBuildInputs = [ makeWrapper ];
  makeWrapperArgs = [
    "--set"
    "GREP_COLORS"
    "mt=1;32"
  ]
  ++ [
    "--add-flags"
    "--color=auto"
  ];

  buildCommand = ''
    mkdir $out
    ${lndir}/bin/lndir -silent ${gnugrep} $out

    rm $out/bin/grep
    makeWrapper ${gnugrep}/bin/grep $out/bin/grep "''${makeWrapperArgs[@]}"
  '';

  meta = {
    description = "grep with colors";
    mainProgram = "grep";
  };
}
