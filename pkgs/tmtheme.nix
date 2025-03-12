{
  lib,
  stdenvNoCC,
  catppuccin,
  nur,
  theme ? "catppuccin_mocha",
}:
let
  catppuccinSrc =
    variant:
    catppuccin.override {
      inherit variant;
      themeList = [ "bat" ];
    };

  rosepineSrc =
    variant: "${nur.repos.josh.rose-pine-tmtheme}/share/rose-pine/tmtheme/${variant}.tmTheme";

  tokyonightSrc =
    variant: "${nur.repos.josh.tokyonight-extras}/share/tokyonight/sublime/${variant}.tmTheme";

  themeSrcs = {
    "catppuccin_frappe" = "${catppuccinSrc "frappe"}/bat/Catppuccin Frappe.tmTheme";
    "catppuccin_latte" = "${catppuccinSrc "latte"}/bat/Catppuccin Latte.tmTheme";
    "catppuccin_macchiato" = "${catppuccinSrc "macchiato"}/bat/Catppuccin Macchiato.tmTheme";
    "catppuccin_mocha" = "${catppuccinSrc "mocha"}/bat/Catppuccin Mocha.tmTheme";
    "rosepine_dawn" = "${rosepineSrc "rose-pine-dawn"}";
    "rosepine_moon" = "${rosepineSrc "rose-pine-moon"}";
    "rosepine" = "${rosepineSrc "rose-pine"}";
    "tokyonight_day" = "${tokyonightSrc "tokyonight_day"}";
    "tokyonight_moon" = "${tokyonightSrc "tokyonight_moon"}";
    "tokyonight_night" = "${tokyonightSrc "tokyonight_night"}";
    "tokyonight_storm" = "${tokyonightSrc "tokyonight_storm"}";
  };

  themeNames = {
    "catppuccin_frappe" = "Catppuccin Frappe";
    "catppuccin_latte" = "Catppuccin Latte";
    "catppuccin_macchiato" = "Catppuccin Macchiato";
    "catppuccin_mocha" = "Catppuccin Mocha";
    "rosepine_dawn" = "Rose Pine Dawn";
    "rosepine_moon" = "Rose Pine Moon";
    "rosepine" = "Rose Pine";
    "tokyonight_day" = "Tokyo Night Day";
    "tokyonight_moon" = "Tokyo Night Moon";
    "tokyonight_night" = "Tokyo Night Night";
    "tokyonight_storm" = "Tokyo Night Storm";
  };

  themeName = builtins.getAttr theme themeNames;

  themeMeta =
    if (lib.strings.hasPrefix "catppuccin" theme) then
      catppuccin.meta
    else if (lib.strings.hasPrefix "rosepine" theme) then
      nur.repos.josh.rose-pine-tmtheme.meta
    else if (lib.strings.hasPrefix "tokyonight" theme) then
      nur.repos.josh.tokyonight-extras.meta
    else
      null;

  themes = builtins.attrNames themeSrcs;
in
assert (lib.asserts.assertOneOf "theme" theme themes);
stdenvNoCC.mkDerivation {
  name = "${theme}.tmTheme";

  __structuredAttrs = true;

  themeSrc = builtins.getAttr theme themeSrcs;

  buildCommand = ''
    cp "$themeSrc" $out
  '';

  meta = {
    inherit themeName;
    description = "${themeName} TextMate theme";
    inherit (themeMeta) homepage license;
  };
}
