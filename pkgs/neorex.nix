{
  lib,
  stdenvNoCC,
  runCommand,
  lndir,
  makeWrapper,
  nur,
  nixbits,
}:
let
  inherit (nur.repos.josh) neorex;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit (neorex) pname version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    lndir
    makeWrapper
  ];

  # neorex spawns `nvim --embed` from PATH, so the configured wrapper supplies
  # the config, plugins, and $THEME selection.
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.strings.makeBinPath [ nixbits.neovim ])
  ];

  buildCommand = ''
    mkdir $out
    lndir -silent ${neorex} $out

    rm $out/bin/neorex
    makeWrapper ${neorex}/bin/neorex $out/bin/neorex "''${makeWrapperArgs[@]}"
  '';

  passthru.tests.help = runCommand "test-neorex-help" { } ''
    grep --quiet --fixed-strings '${nixbits.neovim}/bin' ${lib.getExe finalAttrs.finalPackage}
    ${lib.getExe finalAttrs.finalPackage} help
    touch $out
  '';

  inherit (neorex) meta;
})
