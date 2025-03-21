{
  lib,
  stdenv,
  writers,
  nixbits,
  theme ? null,
}:
let
  tmux = nixbits.tmux.override { inherit theme; };
  tmux-attach = nixbits.tmux-attach.override { inherit tmux; };

  # C-Space
  leader-char = "\\u0000";

  macKeyboardBindings = [
    # tmux leader alias: <leader>
    {
      mods = "Command";
      key = "B";
      chars = leader-char;
    }

    # tmux create window: <leader> c
    {
      mods = "Command";
      key = "T";
      chars = "${leader-char}c";
    }

    # tmux close window: <leader> & y
    {
      mods = "Command";
      key = "W";
      chars = "${leader-char}&y";
    }

    # tmux split horizontal: <leader> "
    {
      mods = "Command";
      key = "D";
      chars = "${leader-char}\"";
    }
    {
      mods = "Option|Shift|Command";
      key = "H";
      chars = "${leader-char}\"";
    }

    # tmux split vertical: <leader> %
    # {
    #   mods = "Command";
    #   key = "";
    #   chars = "${leader-char}%";
    # }
    {
      mods = "Option|Shift|Command";
      key = "V";
      chars = "${leader-char}%";
    }

    # tmux close split: <leader> x
    {
      mods = "Command|Shift";
      key = "D";
      chars = "${leader-char}x";
    }

    # tmux next window: <leader> n
    {
      mods = "Command|Shift";
      key = "}";
      chars = "${leader-char}n";
    }
    {
      mods = "Control";
      key = "Tab";
      chars = "${leader-char}n";
    }

    # tmux previous window: <leader> p
    {
      mods = "Command|Shift";
      key = "{";
      chars = "${leader-char}p";
    }
    {
      mods = "Control|Shift";
      key = "Tab";
      chars = "${leader-char}p";
    }

    # tmux go to window number
    {
      mods = "Command";
      key = "Key1";
      chars = "${leader-char}1";
    }
    {
      mods = "Command";
      key = "Key2";
      chars = "${leader-char}2";
    }
    {
      mods = "Command";
      key = "Key3";
      chars = "${leader-char}3";
    }
    {
      mods = "Command";
      key = "Key4";
      chars = "${leader-char}4";
    }
    {
      mods = "Command";
      key = "Key5";
      chars = "${leader-char}5";
    }
    {
      mods = "Command";
      key = "Key6";
      chars = "${leader-char}6";
    }
    {
      mods = "Command";
      key = "Key7";
      chars = "${leader-char}7";
    }
    {
      mods = "Command";
      key = "Key8";
      chars = "${leader-char}8";
    }
    {
      mods = "Command";
      key = "Key9";
      chars = "${leader-char}9";
    }
  ];

  linuxKeyboardBindings = [
    # TODO
  ];

  config = {
    terminal.shell.program = lib.getExe tmux-attach;
    keyboard.bindings =
      (lib.lists.optionals stdenv.hostPlatform.isDarwin macKeyboardBindings)
      ++ (lib.lists.optionals stdenv.hostPlatform.isLinux linuxKeyboardBindings);
  };
in
(writers.writeTOML "tmux.toml" config).overrideAttrs {
  name = "alacritty-tmux-config";
  meta = {
    description = "Alacritty tmux config";
    platforms = lib.platforms.all;
  };
}
