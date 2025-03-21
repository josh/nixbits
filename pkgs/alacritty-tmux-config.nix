{
  lib,
  writers,
  nixbits,
  theme ? null,
}:
let
  tmux = nixbits.tmux.override { inherit theme; };
  tmux-attach = nixbits.tmux-attach.override { inherit tmux; };

  config = {
    terminal.shell.program = lib.getExe tmux-attach;
    # env.SHELL = lib.getExe zsh;
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
(writers.writeTOML "tmux.toml" config).overrideAttrs {
  name = "alacritty-tmux-config";
  meta = {
    description = "Alacritty macOS tmux config";
    # TODO: Add linux keybindings
    platforms = lib.platforms.darwin;
  };
}
