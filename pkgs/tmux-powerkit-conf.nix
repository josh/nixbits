{
  lib,
  stdenvNoCC,
  nur,
  powerkitThemeVariation ? "night",
}:
let
  variation =
    assert (lib.asserts.assertOneOf "variation" powerkitThemeVariation variations);
    powerkitThemeVariation;

  variations = [
    "day"
    "moon"
    "storm"
    "night"
  ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "tmux-powerkit-${finalAttrs.powerkitThemeVariation}-conf";

  __structuredAttrs = true;

  powerkitThemeVariation = variation;

  buildCommand = ''
    substitute ${./tmux-powerkit.conf} $out \
      --replace-fail '@powerkit@' '${nur.repos.josh.tmux-powerkit}' \
      --replace-fail '@powerkit_theme_variant@' "$powerkitThemeVariation"
  '';

  meta = {
    description = "Tmux powerkit config";
    platforms = lib.platforms.all;
  };
})
