{
  config,
  lib,
  pkgs,
  wlib,
  ...
}:
let
  inherit (pkgs) nixbits;

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

  sourceTheme =
    if config.theme == null then
      envTheme
    else
      assert (lib.asserts.assertOneOf "theme" config.theme (builtins.attrNames themeConfs));
      "source-file '${themeConfs.${config.theme}}'";
in
{
  imports = [ wlib.wrapperModules.tmux ];

  options.theme = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Fixed theme to use instead of selecting one from `$THEME` at startup.";
  };

  config = {
    sourceSensible = true;
    prefix = "C-Space";
    terminal = "tmux-256color";
    updateEnvironment = [ ];
    displayPanesColour = "blue";
    escapeTime = 10;
    historyLimit = 50000;
    allowPassthrough = false;
    modeKeys = "vi";
    disableConfirmationPrompt = false;
    plugins = [ pkgs.tmuxPlugins.yank ];

    configAfter = ''
      set -g default-command '${config.shell}'

      ${sourceTheme}

      ${builtins.readFile ./tmux.conf}
    '';

    passthru.tests = {
      version = pkgs.testers.testVersion {
        package = config.wrapper;
        command = "tmux -V";
        inherit (config.wrapper) version;
      };
    };
  };
}
