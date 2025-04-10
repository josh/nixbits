{
  lib,
  stdenvNoCC,
  nur,
  tokyonightVariation ? "night",
}:
let
  variation =
    assert (lib.asserts.assertOneOf "variation" tokyonightVariation variations);
    tokyonightVariation;

  variations = [
    "day"
    "moon"
    "storm"
    "night"
  ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "tmux-tokyonight-${finalAttrs.tokyonightVariation}-conf";

  __structuredAttrs = true;

  tokyonightVariation = variation;

  buildCommand = ''
    substitute ${./tmux-tokyonight.conf} $out \
      --replace-fail '@tokyonight@' '${nur.repos.josh.tmux-tokyo-night}' \
      --replace-fail '@tokyonight_theme_variation@' "$tokyonightVariation"
  '';

  meta = {
    description = "Tmux tokyonight config";
    platforms = lib.platforms.all;
  };
})
