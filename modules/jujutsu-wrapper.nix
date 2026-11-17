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
  commandNames = [
    "clone"
    "init"
    "pull"
    "new-main"
    "untracked"
    "wip-changes"
    "bookmark-clean"
    "git-set-upstream"
  ];
  commands = lib.genAttrs commandNames (
    name:
    config.commands.${name}.override (
      {
        git-config = config.env.GIT_CONFIG_GLOBAL.data;
      }
      # The upstream command inherits JJ_CONFIG from its caller, including jj-clone.
      // lib.optionalAttrs (name != "git-set-upstream") {
        jujutsu-config = config.configFile.path;
      }
      // lib.optionalAttrs (name == "clone") {
        jujutsu-git-set-upstream = commands.git-set-upstream;
      }
    )
  );
  generatedConfig = (pkgs.formats.toml { }).generate "jj-config.toml" config.settings;
in
{
  imports = [ wlib.wrapperModules.jujutsu ];

  options.commands = lib.genAttrs commandNames (
    name:
    lib.mkOption {
      type = lib.types.package;
      default = pkgs.nixbits."jujutsu-${name}";
      description = "Base jj-${name} command package, before applying the shared Git/JJ configuration.";
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
    data = lib.concatMapStrings (name: ''
      ln -s ${commands.${name}}/bin/jj-${name} "${placeholder config.outputName}/bin/jj-${name}"
    '') commandNames;
  };

  config.passthru.tests = import ./jujutsu-wrapper/tests.nix { inherit lib pkgs; };

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
