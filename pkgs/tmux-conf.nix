{
  lib,
  stdenvNoCC,
  bash,
  tmuxPlugins,
  nixbits,
  interactiveShell ? "${bash}/bin/bash",
  theme ? null,
}:
let
  validThemes = builtins.attrNames themeConfs;

  sourceTheme =
    if theme == null then
      envTheme
    else
      assert (lib.asserts.assertOneOf "theme" theme validThemes);
      "source-file '${themeConfs.${theme}}'";

  themeConfs = {
    "tokyonight_day" = nixbits.tmux-powerkit-conf.override { powerkitThemeVariation = "day"; };
    "tokyonight_moon" = nixbits.tmux-powerkit-conf.override { powerkitThemeVariation = "moon"; };
    "tokyonight_storm" = nixbits.tmux-powerkit-conf.override { powerkitThemeVariation = "storm"; };
    "tokyonight_night" = nixbits.tmux-powerkit-conf.override { powerkitThemeVariation = "night"; };
    "catppuccin_frappe" = nixbits.tmux-catppuccin-conf.override { catppuccinFlavor = "frappe"; };
    "catppuccin_latte" = nixbits.tmux-catppuccin-conf.override { catppuccinFlavor = "latte"; };
    "catppuccin_macchiato" = nixbits.tmux-catppuccin-conf.override { catppuccinFlavor = "macchiato"; };
    "catppuccin_mocha" = nixbits.tmux-catppuccin-conf.override { catppuccinFlavor = "mocha"; };
    "rosepine_moon" = nixbits.tmux-rosepine-conf.override { rosepineVariant = "moon"; };
    "rosepine_dawn" = nixbits.tmux-rosepine-conf.override { rosepineVariant = "dawn"; };
    "rosepine" = nixbits.tmux-rosepine-conf.override { rosepineVariant = "main"; };
  };

  envTheme = "run-shell 'case \"$THEME\" in ${
    lib.strings.concatMapStrings (
      t:
      if t.tmux == null then
        "${t.pattern}) ;; "
      else
        "${t.pattern}) tmux source-file \"${themeConfs.${t.tmux}}\" ;; "
    ) nixbits.themes
  }esac'";
in
stdenvNoCC.mkDerivation {
  name = "tmux-conf";

  __structuredAttrs = true;

  inherit (tmuxPlugins) sensible yank;
  inherit sourceTheme;
  inherit interactiveShell;

  buildCommand = ''
    substitute ${./tmux.conf} $out \
      --replace-fail '@sensible@' "$sensible" \
      --replace-fail '@yank@' "$yank" \
      --replace-fail '@sourceTheme@' "$sourceTheme" \
      --replace-fail '@interactiveShell@' "$interactiveShell"
  '';

  meta = {
    description = "Configuration for the tmux terminal multiplexer";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
