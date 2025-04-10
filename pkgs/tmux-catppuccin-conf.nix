{
  lib,
  stdenvNoCC,
  nur,
  catppuccinFlavor ? "mocha",
}:
let
  flavor =
    assert (lib.asserts.assertOneOf "flavor" catppuccinFlavor flavors);
    catppuccinFlavor;

  flavors = [
    "frappe"
    "latte"
    "macchiato"
    "mocha"
  ];

  statusBackgrounds = {
    "frappe" = "#303446";
    "latte" = "#eff1f5";
    "macchiato" = "#24273a";
    "mocha" = "#1e1e2e";
  };

in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "tmux-catppuccin-${finalAttrs.catppuccinFlavor}-conf";

  __structuredAttrs = true;

  catppuccinFlavor = flavor;
  catppuccinStatusBackground = statusBackgrounds.${finalAttrs.catppuccinFlavor};

  buildCommand = ''
    substitute ${./tmux-catppuccin.conf} $out \
      --replace-fail '@catppuccin@' '${nur.repos.josh.tmux-catppuccin}' \
      --replace-fail '@catppuccin_flavor@' "$catppuccinFlavor" \
      --replace-fail '@catppuccin_status_background@' "$catppuccinStatusBackground"
  '';

  meta = {
    description = "Tmux catppuccin config";
    platforms = lib.platforms.all;
  };
})
