{
  config,
  lib,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.wrapperModules.neovim ];

  options.nixLsp.enable = lib.mkEnableOption "Nix language support with nil and nixfmt";

  config = {
    package = pkgs.neovim-unwrapped;
    # makeBinaryWrapper rejects the ";;" LUA_PATH suffix this module adds
    # (GHSA-p7v3-pr2c-8584); return to "binary" once nix-wrapper-modules is fixed.
    wrapperImplementation = "shell";
    binName = "nvim";

    settings.config_directory = ../../pkgs/neovim;
    settings.block_normal_config = true;
    hosts.python3.nvim-host.enable = false;
    hosts.node.nvim-host.enable = false;
    hosts.ruby.nvim-host.enable = false;

    specs = {
      nix-lsp = lib.mkIf config.nixLsp.enable {
        data = null;
        after = [ "INIT_MAIN" ];
        config = builtins.readFile ./neovim/nix-lsp.lua;
      };
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
    runtimePkgs = [
      pkgs.jujutsu
    ]
    ++ lib.optionals config.nixLsp.enable [
      pkgs.nil
      pkgs.nixfmt
    ];

    # The wrapper passes the ordered mappings to Lua for startup selection.
    env.NIXBITS_NVIM_THEMES = builtins.toJSON (
      map (t: { inherit (t) pattern; } // t.neovim) pkgs.nixbits.themes
    );

    drv.name = "neovim-${pkgs.neovim-unwrapped.version}";
    drv.version = pkgs.neovim-unwrapped.version;
    drv.meta = {
      inherit (pkgs.neovim-unwrapped.meta) homepage license platforms;
      description = "Neovim with jj.nvim and themes selected by $THEME";
    };

    passthru.tests = lib.filesystem.packagesFromDirectoryRecursive {
      callPackage = pkgs.newScope { neovim = config.wrapper; };
      directory = ./neovim/tests;
    };
  };
}
