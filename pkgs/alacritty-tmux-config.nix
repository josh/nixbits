{
  lib,
  writers,
  zsh,
  nur,
  nixbits,
  theme ? "tokyonight_moon",
}:
let
  tmux = nixbits.tmux.override { inherit theme; };
  tmux-attach = nixbits.tmux-attach.override { inherit tmux; };

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
  themes = builtins.attrNames themeImports;

  themeImport =
    assert (lib.asserts.assertOneOf "theme" theme themes);
    themeImports.${theme};

  config = {
    general.import = [ themeImport ];

    terminal = {
      shell = {
        program = lib.getExe zsh;
        args = [
          "--login"
          "-c"
          (lib.getExe tmux-attach)
        ];
      };
    };

    env = {
      THEME = theme;
    };

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
      normal.family = "BerkeleyMono Nerd Font Mono";
      size = 19;
    };

    keyboard.bindings = [
      # tmux leader alias: Ctrl-b
      {
        key = "B";
        mods = "Command";
        chars = "\u0000";
      }

      # tmux create window: Ctrl-b c
      {
        key = "T";
        mods = "Command";
        chars = "\u0000c";
      }

      # tmux close window: Ctrl-b & y
      {
        key = "W";
        mods = "Command";
        chars = "\u0000&y";
      }

      # tmux split horizontal: Ctrl-b "
      {
        key = "D";
        mods = "Command";
        chars = "\u0000\"";
      }
      {
        key = "H";
        mods = "Option|Shift|Command";
        chars = "\u0000\"";
      }

      # tmux split vertical: Ctrl-b %
      # {
      #   key = "";
      #   mods = "Command";
      #   chars = "\u0000%";
      # }
      {
        key = "V";
        mods = "Option|Shift|Command";
        chars = "\u0000%";
      }

      # tmux close split: Ctrl-b x
      {
        key = "D";
        mods = "Command|Shift";
        chars = "\u0000x";
      }

      # tmux next window: Ctrl-b n
      {
        key = "}";
        mods = "Command|Shift";
        chars = "\u0000n";
      }
      {
        key = "Tab";
        mods = "Control";
        chars = "\u0000n";
      }

      # tmux previous window: Ctrl-b p
      {
        key = "{";
        mods = "Command|Shift";
        chars = "\u0000p";
      }
      {
        key = "Tab";
        mods = "Control|Shift";
        chars = "\u0000p";
      }

      # tmux go to window number
      {
        key = "Key1";
        mods = "Command";
        chars = "\u00001";
      }
      {
        key = "Key2";
        mods = "Command";
        chars = "\u00002";
      }
      {
        key = "Key3";
        mods = "Command";
        chars = "\u00003";
      }
      {
        key = "Key4";
        mods = "Command";
        chars = "\u00004";
      }
      {
        key = "Key5";
        mods = "Command";
        chars = "\u00005";
      }
      {
        key = "Key6";
        mods = "Command";
        chars = "\u00006";
      }
      {
        key = "Key7";
        mods = "Command";
        chars = "\u00007";
      }
      {
        key = "Key8";
        mods = "Command";
        chars = "\u00008";
      }
      {
        key = "Key9";
        mods = "Command";
        chars = "\u00009";
      }
    ];
  };
in
(writers.writeTOML "alacritty.toml" config).overrideAttrs {
  name = "alacritty-tmux-config";
  meta = {
    description = "Alacritty macOS tmux config";
    platforms = lib.platforms.darwin;
  };
}
