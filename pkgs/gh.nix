{
  stdenvNoCC,
  makeWrapper,
  lndir,
  gh,
  nixbits,
}:
stdenvNoCC.mkDerivation {
  name = "gh";

  __structuredAttrs = true;

  nativeBuildInputs = [ makeWrapper ];
  makeWrapperArgs =
    [
      "--set"
      "GH_CONFIG_DIR"
      "${nixbits.gh-config-dir}"
    ]
    ++ [
      "--set"
      "GH_NO_UPDATE_NOTIFIER"
      "1"
    ]
    ++ [
      "--set"
      "GH_NO_EXTENSION_UPDATE_NOTIFIER"
      "1"
    ];

  buildCommand = ''
    mkdir $out
    ${lndir}/bin/lndir -silent ${gh} $out

    rm $out/bin/gh
    makeWrapper ${gh}/bin/gh $out/bin/gh "''${makeWrapperArgs[@]}"
  '';

  inherit (gh) meta;
}
