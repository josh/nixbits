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
  validThemes = builtins.attrNames sourceThemes;

  sourceTheme =
    if theme == null then
      envTheme
    else
      assert (lib.asserts.assertOneOf "theme" theme validThemes);
      sourceThemes.${theme};

  sourceThemes = {
    "tokyonight_day" = ''
      source-file '${nixbits.tmux-tokyonight-conf.override { tokyonightVariation = "day"; }}'
    '';
    "tokyonight_moon" = ''
      source-file '${nixbits.tmux-tokyonight-conf.override { tokyonightVariation = "moon"; }}'
    '';
    "tokyonight_storm" = ''
      source-file '${nixbits.tmux-tokyonight-conf.override { tokyonightVariation = "storm"; }}'
    '';
    "tokyonight_night" = ''
      source-file '${nixbits.tmux-tokyonight-conf.override { tokyonightVariation = "night"; }}'
    '';
    "catppuccin_frappe" = ''
      source-file '${nixbits.tmux-catppuccin-conf.override { catppuccinFlavor = "frappe"; }}'
    '';
    "catppuccin_latte" = ''
      source-file '${nixbits.tmux-catppuccin-conf.override { catppuccinFlavor = "latte"; }}'
    '';
    "catppuccin_macchiato" = ''
      source-file '${nixbits.tmux-catppuccin-conf.override { catppuccinFlavor = "macchiato"; }}'
    '';
    "catppuccin_mocha" = ''
      source-file '${nixbits.tmux-catppuccin-conf.override { catppuccinFlavor = "mocha"; }}'
    '';
    "rosepine_moon" = ''
      source-file '${nixbits.tmux-rosepine-conf.override { rosepineVariant = "moon"; }}'
    '';
    "rosepine_dawn" = ''
      source-file '${nixbits.tmux-rosepine-conf.override { rosepineVariant = "dawn"; }}'
    '';
    "rosepine" = ''
      source-file '${nixbits.tmux-rosepine-conf.override { rosepineVariant = "main"; }}'
    '';
  };

  envTheme = ''
    if-shell '[ "$THEME" = "tokyonight_day" ]' {
      ${sourceThemes.tokyonight_day}
    }
    if-shell '[ "$THEME" = "tokyonight_moon" ]' {
      ${sourceThemes.tokyonight_moon}
    }
    if-shell '[ "$THEME" = "tokyonight_storm" ]' {
      ${sourceThemes.tokyonight_storm}
    }
    if-shell '[ "$THEME" = "tokyonight_night" ]' {
      ${sourceThemes.tokyonight_night}
    }
    if-shell '[ "$THEME" = "catppuccin_frappe" ]' {
      ${sourceThemes.catppuccin_frappe}
    }
    if-shell '[ "$THEME" = "catppuccin_latte" ]' {
      ${sourceThemes.catppuccin_latte}
    }
    if-shell '[ "$THEME" = "catppuccin_macchiato" ]' {
      ${sourceThemes.catppuccin_macchiato}
    }
    if-shell '[ "$THEME" = "catppuccin_mocha" ]' {
      ${sourceThemes.catppuccin_mocha}
    }
    if-shell '[ "$THEME" = "rosepine_moon" ]' {
      ${sourceThemes.rosepine_moon}
    }
    if-shell '[ "$THEME" = "rosepine_dawn" ]' {
      ${sourceThemes.rosepine_dawn}
    }
    if-shell '[ "$THEME" = "rosepine" ]' {
      ${sourceThemes.rosepine}
    }
  '';
in
stdenvNoCC.mkDerivation {
  name = "tmux-conf";

  __structuredAttrs = true;

  env = {
    inherit (tmuxPlugins) sensible yank;
    inherit sourceTheme;
    inherit interactiveShell;
  };

  buildCommand = ''
    substituteAll ${./tmux.conf} $out
  '';

  meta = {
    description = "Tmux config";
    platforms = lib.platforms.all;
  };
}
