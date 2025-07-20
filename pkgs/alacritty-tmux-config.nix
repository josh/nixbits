{
  lib,
  stdenv,
  writers,
  nixbits,
  interactiveShell ? "${nixbits.zsh}/bin/zsh",
  theme ? null,
}:
let
  tmux = nixbits.tmux.override { inherit interactiveShell theme; };
  tmux-attach = nixbits.tmux-attach.override { inherit tmux; };

  tmux-command = command: tmux-command-with command [ ];
  tmux-command-with = command: args: {
    program = "${lib.getExe tmux}";
    args = [ command ] ++ args;
  };

  macKeyboardBindings = [
    # tmux create window: <leader> c
    {
      mods = "Command";
      key = "T";
      command = tmux-command "new-window";
    }

    # tmux close window: <leader> & y
    {
      mods = "Command";
      key = "W";
      command = tmux-command "kill-window";
    }

    # tmux split horizontal: <leader> "
    {
      mods = "Command";
      key = "D";
      command = tmux-command-with "split-window" [ "-v" ];
    }
    {
      mods = "Option|Shift|Command";
      key = "H";
      command = tmux-command-with "split-window" [ "-v" ];
    }

    # tmux split vertical: <leader> %
    # {
    #   mods = "Command";
    #   key = "";
    #   command = tmux-command-with "split-window" [ "-h" ];
    # }
    {
      mods = "Option|Shift|Command";
      key = "V";
      command = tmux-command-with "split-window" [ "-h" ];
    }

    # tmux close split: <leader> x
    {
      mods = "Command|Shift";
      key = "D";
      command = tmux-command "kill-pane";
    }

    # tmux next window: <leader> n
    {
      mods = "Command|Shift";
      key = "}";
      command = tmux-command "next-window";
    }
    {
      mods = "Control";
      key = "Tab";
      command = tmux-command "next-window";
    }

    # tmux previous window: <leader> p
    {
      mods = "Command|Shift";
      key = "{";
      command = tmux-command "previous-window";
    }
    {
      mods = "Control|Shift";
      key = "Tab";
      command = tmux-command "previous-window";
    }
  ]
  ++ macSelectWindowBindings;

  # tmux go to window number
  macSelectWindowBindings = builtins.genList (
    i:
    let
      n = builtins.toString (i + 1);
    in
    {
      mods = "Command";
      key = "Key${n}";
      command = tmux-command-with "select-window" [
        "-t"
        n
      ];
    }
  ) 8;

  linuxKeyboardBindings = [
    # TODO
  ];

  config = {
    terminal.shell.program = lib.getExe tmux-attach;

    window.decorations = if stdenv.hostPlatform.isDarwin then "Buttonless" else "Full";

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
