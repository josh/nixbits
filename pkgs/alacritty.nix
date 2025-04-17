{
  lib,
  stdenvNoCC,
  makeWrapper,
  alacritty,
  lndir,
  nixbits,
  theme ? "tokyonight_moon",
  interactiveShell ? nixbits.zsh,
  enableTmux ? true,
}:
let
  alacrittyConfig = nixbits.alacritty-config.override {
    inherit interactiveShell theme enableTmux;
  };
in
stdenvNoCC.mkDerivation (_finalAttrs: {
  pname = if theme != null then "${alacritty.pname}-${theme}" else alacritty.pname;
  inherit (alacritty) version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
    lndir
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
})
