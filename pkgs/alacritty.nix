{
  lib,
  stdenvNoCC,
  lndir,
  makeWrapper,
  alacritty,
  nixbits,
  theme ? "tokyonight_moon",
  interactiveShell ? "${nixbits.zsh}/bin/zsh",
  enableTmux ? true,
}:
let
  alacrittyConfig = nixbits.alacritty-config.override {
    inherit interactiveShell theme enableTmux;
  };
in
stdenvNoCC.mkDerivation {
  pname = if theme != null then "${alacritty.pname}-${theme}" else alacritty.pname;
  inherit (alacritty) version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    lndir
    makeWrapper
  ];

  makeWrapperArgs = [
    "--add-flags"
    "--config-file ${alacrittyConfig}"
  ];

  buildCommand = ''
    mkdir -p $out
    lndir -silent ${alacritty} $out

    rm $out/bin/alacritty
    makeWrapper ${alacritty}/bin/alacritty $out/bin/alacritty "''${makeWrapperArgs[@]}"
  '';

  meta = {
    inherit (alacritty.meta) description license;
    mainProgram = "alacritty";
    platforms = lib.platforms.all;
  };
}
