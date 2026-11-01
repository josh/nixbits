{
  config,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.wrapperModules.neovim ];

  package = pkgs.neovim-unwrapped;
  wrapperImplementation = "binary";
  binName = "nvim";

  settings.config_directory = ../pkgs/neovim;
  settings.block_normal_config = true;
  hosts.python3.nvim-host.enable = false;
  hosts.node.nvim-host.enable = false;
  hosts.ruby.nvim-host.enable = false;

  specs = {
    jj = {
      data = pkgs.vimPlugins.jj-nvim;
      config = "require('jj').setup({})";
    };
    tokyonight.data = pkgs.vimPlugins.tokyonight-nvim;
    catppuccin.data = pkgs.vimPlugins.catppuccin-nvim;
    rose-pine.data = pkgs.vimPlugins.rose-pine;
    theme = {
      data = null;
      after = [ "INIT_MAIN" ];
      config = "require('theme')";
    };
  };
  runtimePkgs = [ pkgs.jujutsu ];

  # The binary wrapper passes the ordered mappings to Lua for startup selection.
  env.NIXBITS_NVIM_THEMES = builtins.toJSON (
    map (t: { inherit (t) pattern; } // t.neovim) pkgs.nixbits.themes
  );

  drv.name = "neovim-${pkgs.neovim-unwrapped.version}";
  drv.version = pkgs.neovim-unwrapped.version;
  drv.meta = {
    inherit (pkgs.neovim-unwrapped.meta) homepage license platforms;
    description = "Neovim with jj.nvim and themes selected by $THEME";
  };

  passthru.tests.startup =
    pkgs.runCommand "test-neovim-startup"
      {
        nativeBuildInputs = [ config.wrapper ];
        env.JJ_BIN = "${pkgs.jujutsu}/bin/jj";
        env.NVIM_UNWRAPPED = "${pkgs.neovim-unwrapped}/bin/nvim";
      }
      ''
        export HOME="$PWD/home"
        export XDG_CONFIG_HOME="$HOME/.config"
        export XDG_STATE_HOME="$HOME/.local/state"
        export XDG_CACHE_HOME="$HOME/.cache"
        export TERM=xterm-256color
        mkdir -p "$XDG_CONFIG_HOME/nvim/plugin"
        echo 'error("local init.lua must not load")' > "$XDG_CONFIG_HOME/nvim/init.lua"
        echo 'vim.g.local_plugin_loaded = true' > "$XDG_CONFIG_HOME/nvim/plugin/sentinel.lua"
        test "$(ls ${config.wrapper}/bin)" = nvim
        unset THEME
        "$NVIM_UNWRAPPED" --clean --headless -c 'luafile ${../pkgs/neovim-test-defaults.lua}' -c 'qa!'
        nvim --headless -i NONE \
          -c 'lua local ok, err = pcall(dofile, "${../pkgs/neovim-test.lua}"); if not ok then print(err); vim.cmd("cquit 1") end' \
          -c 'qa!'
        touch "$out"
      '';
}
