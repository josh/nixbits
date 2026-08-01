{
  stdenvNoCC,
  lndir,
  makeWrapper,
  gnugrep,
}:
stdenvNoCC.mkDerivation {
  pname = "grep";
  inherit (gnugrep) version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    lndir
    makeWrapper
  ];
  makeWrapperArgs = [
    "--set"
    "GREP_COLORS"
    "mt=1;32"
    "--add-flags"
    "--color=auto"
  ];

  buildCommand = ''
    mkdir $out
    lndir -silent ${gnugrep} $out

    rm $out/bin/grep
    makeWrapper ${gnugrep}/bin/grep $out/bin/grep "''${makeWrapperArgs[@]}"
  '';

  meta = {
    description = "Pattern search tool with colored output enabled";
    inherit (gnugrep.meta) license;
    mainProgram = "grep";
    inherit (gnugrep.meta) platforms;
  };
}
