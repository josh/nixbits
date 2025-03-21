{
  lib,
  writers,
  bashInteractive,
  nur,
  nixbits,
  interactiveShell ? bashInteractive,
  theme ? "tokyonight_moon",
  enableTmux ? true,
}:
let
  tmuxConfig = nixbits.alacritty-tmux-config.override { inherit theme; };

  themeImports = {
    "catppuccin_frappe" = "${nur.repos.josh.alacritty-catppuccin}/catppuccin-frappe.toml";
    "catppuccin_latte" = "${nur.repos.josh.alacritty-catppuccin}/catppuccin-latte.toml";
    "catppuccin_macchiato" = "${nur.repos.josh.alacritty-catppuccin}/catppuccin-macchiato.toml";
    "catppuccin_mocha" = "${nur.repos.josh.alacritty-catppuccin}/catppuccin-mocha.toml";
    "rosepine_dawn" = "${nur.repos.josh.alacritty-rose-pine}/rose-pine-dawn.toml";
    "rosepine_moon" = "${nur.repos.josh.alacritty-rose-pine}/rose-pine-moon.toml";
    "rosepine" = "${nur.repos.josh.alacritty-rose-pine}/rose-pine.toml";
    "tokyonight_day" =
      "${nur.repos.josh.tokyonight-extras}/share/tokyonight/alacritty/tokyonight_day.toml";
    "tokyonight_moon" =
      "${nur.repos.josh.tokyonight-extras}/share/tokyonight/alacritty/tokyonight_moon.toml";
    "tokyonight_night" =
      "${nur.repos.josh.tokyonight-extras}/share/tokyonight/alacritty/tokyonight_night.toml";
    "tokyonight_storm" =
      "${nur.repos.josh.tokyonight-extras}/share/tokyonight/alacritty/tokyonight_storm.toml";
  };
  validThemes = builtins.attrNames themeImports;
  themeImport =
    assert (lib.asserts.assertOneOf "theme" theme validThemes);
    themeImports.${theme};

  shell = lib.getExe interactiveShell;

  config = {
    general.import =
      (lib.lists.optional (theme != null) themeImport) ++ (lib.lists.optional enableTmux tmuxConfig);

    terminal = {
      shell = if enableTmux then { } else { program = shell; };
    };

    env = {
      "SHELL" = shell;
    } // lib.attrsets.optionalAttrs (theme != null) { THEME = theme; };

    window = {
      dimensions = {
        columns = 120;
        lines = 40;
      };
      padding = {
        x = 10;
        y = 10;
      };
      decorations = "Buttonless";
      resize_increments = true;
      option_as_alt = "Both";
    };

    font = {
      # TODO: Don't enable this by default
      normal.family = "BerkeleyMono Nerd Font Mono";
      size = 19;
    };
  };
in
(writers.writeTOML "alacritty.toml" config).overrideAttrs {
  name = "alacritty-config";
  meta = {
    description = "Alacritty macOS config";
    # TODO: Improve linux support
    platforms = lib.platforms.darwin;
  };
}
