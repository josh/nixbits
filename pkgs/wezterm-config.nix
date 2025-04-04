{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  theme ? null,
}:
let
  # TODO: Extract to nurpkgs
  tabline = fetchFromGitHub {
    owner = "michaelbrusegard";
    repo = "tabline.wez";
    tag = "v1.6.0";
    hash = "sha256-1/lA0wjkvpIRauuhDhaV3gzCFSql+PH39/Kpwzrbk54=";
  };

  colorSchemes = {
    "catppuccin_frappe" = "Catppuccin Frappe";
    "catppuccin_latte" = "Catppuccin Latte";
    "catppuccin_macchiato" = "Catppuccin Macchiato";
    "catppuccin_mocha" = "Catppuccin Mocha";
    "rosepine_dawn" = "rose-pine-dawn";
    "rosepine_moon" = "rose-pine-moon";
    "rosepine" = "rose-pine";
    "tokyonight_day" = "Tokyo Night Day";
    "tokyonight_moon" = "Tokyo Night Moon";
    "tokyonight_night" = "Tokyo Night";
    "tokyonight_storm" = "Tokyo Night Storm";
  };
  validThemes = builtins.attrNames colorSchemes;

  colorScheme =
    if theme == null then
      null
    else
      (
        assert (lib.asserts.assertOneOf "theme" theme validThemes);
        colorSchemes.${theme}
      );
in
stdenvNoCC.mkDerivation {
  name = "wezterm-config";

  __structuredAttrs = true;

  env = {
    theme = if theme == null then "" else theme;
    colorScheme = if theme == null then "" else colorScheme;
    inherit tabline;
  };

  buildCommand = ''
    substituteAll "${./wezterm-config.lua}" "$out"
  '';

  meta = {
    description = "Wezterm config";
    platforms = lib.platforms.all;
  };
}
