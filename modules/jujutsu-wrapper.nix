{
  config,
  lib,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.wrapperModules.jujutsu ];

  options.gitWrapper = lib.mkOption {
    type = lib.types.package;
    default = pkgs.nixbits.git;
    description = "Evaluated Git wrapper supplying the Git executable and default JJ identity.";
  };

  options.configFile = lib.mkOption {
    type = lib.types.submodule {
      options.path = lib.mkOption {
        type = wlib.types.stringable;
        default = config.constructFiles.generatedConfig.path;
        description = "JJ configuration file; defaults to the generated settings.";
      };
    };
    default = { };
    description = "Configuration file used by JJ.";
  };

  # The upstream module sets JJ_CONFIG directly to its generated file.
  config.env.JJ_CONFIG = lib.mkForce config.configFile.path;

  config.settings = {
    user = {
      name = lib.mkDefault config.gitWrapper.configuration.settings.user.name;
      email = lib.mkDefault config.gitWrapper.configuration.settings.user.email;
    };

    ui = {
      default-command = [ "log" ];
      editor = lib.getExe pkgs.neovim;
      paginate = "never";
      diff-editor = ":builtin";
    };

    git = {
      executable-path = lib.mkDefault (lib.getExe config.gitWrapper);
    };

    remotes.origin = {
      auto-track-bookmarks = "glob:push-*";
    };

    merge-tools.meld = {
      program = lib.getExe pkgs.meld;
    };

    merge-tools.vimdiff = {
      program = lib.getExe pkgs.vim;
    };

    revset-aliases = {
      "closest_pushable(to)" = "heads(::to & ~description(exact:\"\") & (~empty() | merges()))";
    };

    aliases = {
      fetch = [
        "git"
        "fetch"
        "--all-remotes"
      ];
      push = [
        "git"
        "push"
        "--all"
        "--deleted"
      ];
      tug = [
        "bookmark"
        "advance"
        "--to"
        "closest_pushable(@)"
      ];
      new-parent = [
        "new"
        "--no-edit"
        "--insert-before"
        "@"
      ];
      rebase-all = [
        "rebase"
        "--branch"
        "bookmarks()"
        "--onto"
        "trunk()"
      ];
    };
  };
}
