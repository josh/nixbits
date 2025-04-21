{
  lib,
  stdenvNoCC,
  zellijTheme ? null,
}:
let
  validThemes = [
    "catppuccin-frappe"
    "catppuccin-latte"
    "catppuccin-macchiato"
    "tokyo-night-dark"
    "tokyo-night-light"
    "tokyo-night-storm"
    "tokyo-night"
  ];
in
stdenvNoCC.mkDerivation {
  name = "zellij-config";

  __structuredAttrs = true;

  env = {
    theme =
      if zellijTheme == null then
        "default"
      else
        assert (lib.asserts.assertOneOf "zellijTheme" zellijTheme validThemes);
        zellijTheme;
  };

  buildCommand = ''
    mkdir $out
    substituteAll ${./zellij.kdl} $out/config.kdl
  '';

  meta = {
    description = "Zellij config";
    platforms = lib.platforms.all;
  };
}
