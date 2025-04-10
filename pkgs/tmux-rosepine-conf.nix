{
  lib,
  stdenvNoCC,
  tmuxPlugins,
  rosepineVariant ? "main",
}:
let
  variant =
    assert (lib.asserts.assertOneOf "variation" rosepineVariant variants);
    rosepineVariant;

  variants = [
    "main"
    "moon"
    "dawn"
  ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "tmux-rosepine-${finalAttrs.rosepineVariant}-conf";

  __structuredAttrs = true;

  rosepineVariant = variant;

  buildCommand = ''
    substitute ${./tmux-rosepine.conf} $out \
      --replace-fail '@rosepine@' '${tmuxPlugins.rose-pine}' \
      --replace-fail '@rose_pine_variant@' "$rosepineVariant"
  '';

  meta = {
    description = "Tmux rosepine config";
    platforms = lib.platforms.all;
  };
})
