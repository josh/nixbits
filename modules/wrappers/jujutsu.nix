{
  config,
  lib,
  pkgs,
  wlib,
  ...
}:
let
  gitConfiguration = config.gitWrapper.configuration;
  # Resolve the Git wrapper's output placeholder before passing its config to a helper.
  gitConfig =
    if toString gitConfiguration.configFile.path == gitConfiguration.constructFiles.gitconfig.path then
      gitConfiguration.constructFiles.gitconfig.outPath
    else
      gitConfiguration.configFile.path;
  generatedConfig = (pkgs.formats.toml { }).generate "jj-config.toml" config.settings;
in
{
  imports = [ wlib.wrapperModules.jujutsu ];

  options.watchmanPackage = lib.mkOption {
    type = lib.types.package;
    default = pkgs.watchman;
    description = "Watchman package bundled with JJ when available on the target platform.";
  };

  options.jujutsuPackage = lib.mkOption {
    type = lib.types.package;
    default = pkgs.jujutsu;
    description = "Underlying JJ package to bundle with Watchman and wrap.";
  };

  # Prefer this bundle over the upstream default, while allowing ordinary package overrides.
  config.package = lib.mkOverride 900 (
    pkgs.symlinkJoin {
      pname = "jujutsu";
      inherit (config.jujutsuPackage) version meta;
      paths = [
        config.jujutsuPackage
      ]
      ++ lib.optional config.watchmanPackage.meta.available config.watchmanPackage;
    }
  );

  options.commands = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    default = { };
    description = "Final command packages, keyed by the executable name to install from each package's bin directory.";
  };

  config.commands = lib.mapAttrs (_: lib.mkDefault) (
    import ./jujutsu/commands.nix {
      inherit config;
      inherit (pkgs) nixbits;
    }
  );

  options.gitWrapper = lib.mkOption {
    type = lib.types.package;
    default = pkgs.nixbits.git;
    description = "Evaluated Git wrapper supplying the Git executable and default JJ identity.";
  };

  options.configFile = lib.mkOption {
    type = lib.types.submodule {
      options.path = lib.mkOption {
        type = wlib.types.stringable;
        default = generatedConfig;
        description = "JJ configuration file; defaults to the generated settings.";
      };
    };
    default = { };
    description = "Configuration file used by JJ.";
  };

  # Keep the upstream wrapper-local file available, using the same standalone config.
  config.constructFiles.generatedConfig.builder = lib.mkForce ''
    cp ${generatedConfig} "$2"
  '';

  # The upstream module sets JJ_CONFIG directly to its generated file.
  config.env.JJ_CONFIG = lib.mkForce config.configFile.path;

  config.env.GIT_CONFIG_GLOBAL = lib.mkDefault gitConfig;

  config.buildCommand.jjHelpers = {
    after = [ "symlinkScript" ];
    data = lib.concatStrings (
      lib.mapAttrsToList (name: package: ''
        test -x ${lib.escapeShellArg "${package}/bin/${name}"}
        ln -s ${lib.escapeShellArg "${package}/bin/${name}"} ${lib.escapeShellArg "${placeholder config.outputName}/bin/${name}"}
      '') config.commands
    );
  };

  config.passthru.tests = lib.filesystem.packagesFromDirectoryRecursive {
    inherit (pkgs) callPackage;
    directory = ./jujutsu/tests;
  };

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
