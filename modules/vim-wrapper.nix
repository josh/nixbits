{
  config,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.wrapperModules.vim ];

  package = pkgs.vim;
  wrapperImplementation = "binary";

  plugins = [ ];
  vimrc = builtins.readFile ../pkgs/vimrc;

  drv.name = "vim-${pkgs.vim.version}";
  drv.version = pkgs.vim.version;
  drv.meta = {
    inherit (pkgs.vim.meta) homepage license platforms;
    description = "Vim text editor preconfigured with a custom vimrc";
  };

  passthru.tests.vimrc =
    pkgs.runCommand "test-vim-vimrc" { nativeBuildInputs = [ config.wrapper ]; }
      ''
        export HOME="$PWD"
        export XDG_STATE_HOME="$PWD/state"
        for exe in vim vi view rvim ex; do
          actual="$("$exe" -es -c 'redir >> /dev/stdout | echo "tw=".&textwidth." cp=".&compatible' -c 'qa!' </dev/null)"
          if [[ "$actual" != *"tw=79 cp=0"* ]]; then
            echo "$exe: expected textwidth=79 and nocompatible from the vimrc, but was '$actual'"
            return 1
          fi
        done
        touch $out
      '';
}
