{
  jujutsu,
  neovim,
  neovim-unwrapped,
  runCommand,
}:
runCommand "test-neovim-startup"
  {
    nativeBuildInputs = [ neovim ];
    env.JJ_BIN = "${jujutsu}/bin/jj";
    env.NVIM_UNWRAPPED = "${neovim-unwrapped}/bin/nvim";
  }
  ''
    export HOME="$PWD/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_CACHE_HOME="$HOME/.cache"
    export TERM=xterm-256color
    mkdir -p "$XDG_CONFIG_HOME/nvim/plugin"
    echo 'error("local init.lua must not load")' >"$XDG_CONFIG_HOME/nvim/init.lua"
    echo 'vim.g.local_plugin_loaded = true' >"$XDG_CONFIG_HOME/nvim/plugin/sentinel.lua"
    test "$(ls ${neovim}/bin)" = nvim
    unset THEME
    "$NVIM_UNWRAPPED" --clean --headless -c 'luafile ${../../../../pkgs/neovim-test-defaults.lua}' -c 'qa!'
    nvim --headless -i NONE \
      -c 'lua local ok, err = pcall(dofile, "${../../../../pkgs/neovim-test.lua}"); if not ok then print(err); vim.cmd("cquit 1") end' \
      -c 'qa!'
    touch "$out"
  ''
