{
  lib,
  stdenvNoCC,
  makeWrapper,
  lndir,
  jujutsu,
  lazyjj,
  nixbits,
}:
let
  lazyjj' = lazyjj.overrideAttrs {
    # Disable wrapProgram
    postInstall = "";
    # Disable tests that fail due to jj version incompatibility
    doCheck = false;
  };
in
stdenvNoCC.mkDerivation {
  inherit (lazyjj')
    name
    pname
    version
    meta
    ;

  __structuredAttrs = true;

  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.strings.makeBinPath [ jujutsu ])
  ]
  ++ [
    "--set"
    "JJ_CONFIG"
    "${nixbits.jujutsu-config}"
  ]
  ++ [
    "--set"
    "XDG_CONFIG_HOME"
    "${nixbits.jujutsu-xdg-config-home}"
  ];

  nativeBuildInputs = [
    makeWrapper
    lndir
  ];

  buildCommand = ''
    mkdir $out
    lndir -silent ${lazyjj'} $out

    rm $out/bin/lazyjj
    makeWrapper ${lazyjj'}/bin/lazyjj $out/bin/lazyjj "''${makeWrapperArgs[@]}"
  '';
}
