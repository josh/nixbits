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
  jjInit = pkgs.nixbits.jujutsu-init.override {
    git-config = config.env.GIT_CONFIG_GLOBAL.data;
    jujutsu-config = config.configFile.path;
  };
  jjPull = pkgs.nixbits.jujutsu-pull.override {
    git-config = config.env.GIT_CONFIG_GLOBAL.data;
    jujutsu-config = config.configFile.path;
  };
  jjNewMain = pkgs.nixbits.jujutsu-new-main.override {
    git-config = config.env.GIT_CONFIG_GLOBAL.data;
    jujutsu-config = config.configFile.path;
  };
  generatedConfig = (pkgs.formats.toml { }).generate "jj-config.toml" config.settings;
in
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
    data = ''
      ln -s ${jjInit}/bin/jj-init "${placeholder config.outputName}/bin/jj-init"
      ln -s ${jjPull}/bin/jj-pull "${placeholder config.outputName}/bin/jj-pull"
      ln -s ${jjNewMain}/bin/jj-new-main "${placeholder config.outputName}/bin/jj-new-main"
    '';
  };

  config.passthru.tests.init-module-propagation =
    let
      customGit = pkgs.wlibEvalPackage [
        ./git-wrapper.nix
        {
          settings.user = {
            name = lib.mkForce "Module Author";
            email = lib.mkForce "git@example.com";
          };
          settings.core.excludesFile = lib.mkForce (
            pkgs.writeText "jj-module-gitignore" "ignored-by-module\n"
          );
        }
      ];
      customJj = pkgs.wlibEvalPackage [
        ./jujutsu-wrapper.nix
        {
          gitWrapper = customGit;
          settings.user.email = "jj@example.com";
        }
      ];
    in
    pkgs.runCommand "test-jj-init-module-propagation" { nativeBuildInputs = [ pkgs.git ]; } ''
      export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1
      mkdir -p "$HOME" repo
      cd repo
      git init
      touch visible ignored-by-module
      export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
      ${customJj}/bin/jj-init
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'author.name()')" = "Module Author"
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'author.email()')" = jj@example.com
      test "$(${customJj}/bin/jj file list --ignore-working-copy)" = visible
      touch "$out"
    '';

  config.passthru.tests.pull-module-propagation =
    let
      customGit = pkgs.wlibEvalPackage [
        ./git-wrapper.nix
        {
          settings.user = {
            name = lib.mkForce "Pull Author";
            email = lib.mkForce "git@example.com";
          };
          settings.core.excludesFile = lib.mkForce (
            pkgs.writeText "jj-pull-module-gitignore" "ignored-by-module\n"
          );
          # The selected Git wrapper may have behavior beyond setting its config.
          runShell = [ ''echo git >>"$GIT_EXECUTION_LOG"'' ];
        }
      ];
      customJj = pkgs.wlibEvalPackage [
        ./jujutsu-wrapper.nix
        {
          gitWrapper = customGit;
          settings.user.email = "jj@example.com";
        }
      ];
    in
    pkgs.runCommand "test-jj-pull-module-propagation" { nativeBuildInputs = [ pkgs.git ]; } ''
      export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1 GIT_EXECUTION_LOG="$TMPDIR/git-executions"
      unset GIT_CONFIG_GLOBAL JJ_CONFIG
      mkdir -p "$HOME"
      git init --initial-branch=main seed
      git -C seed config user.name "Seed Author"
      git -C seed config user.email seed@example.com
      git -C seed commit --allow-empty --message initial
      ${customJj}/bin/jj git clone "$PWD/seed" work
      git -C seed commit --allow-empty --message upstream
      upstream=$(git -C seed rev-parse HEAD)
      cd work
      touch visible ignored-by-module
      : >"$GIT_EXECUTION_LOG"
      export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
      ${customJj}/bin/jj-pull
      test -s "$GIT_EXECUTION_LOG"
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r '@-' -T commit_id)" = "$upstream"
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'committer.name()')" = "Pull Author"
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'committer.email()')" = jj@example.com
      test "$(${customJj}/bin/jj file list --ignore-working-copy)" = visible
      touch "$out"
    '';

  config.passthru.tests.new-main-module-propagation =
    let
      customGit = pkgs.wlibEvalPackage [
        ./git-wrapper.nix
        {
          settings.user = {
            name = lib.mkForce "New Main Author";
            email = lib.mkForce "git@example.com";
          };
          settings.core.excludesFile = lib.mkForce (
            pkgs.writeText "jj-new-main-module-gitignore" "ignored-by-module\n"
          );
        }
      ];
      customJj = pkgs.wlibEvalPackage [
        ./jujutsu-wrapper.nix
        {
          gitWrapper = customGit;
          settings.user.email = "jj@example.com";
        }
      ];
    in
    pkgs.runCommand "test-jj-new-main-module-propagation" { nativeBuildInputs = [ pkgs.git ]; } ''
      export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1
      unset GIT_CONFIG_GLOBAL JJ_CONFIG
      mkdir -p "$HOME"
      git init --initial-branch=main seed
      git -C seed config user.name "Seed Author"
      git -C seed config user.email seed@example.com
      git -C seed commit --allow-empty --message initial
      ${customJj}/bin/jj git clone "$PWD/seed" work
      git -C seed commit --allow-empty --message upstream
      upstream=$(git -C seed rev-parse HEAD)
      cd work
      previous=$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T change_id)
      touch visible ignored-by-module
      export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
      ${customJj}/bin/jj-new-main
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r '@-' -T commit_id)" = "$upstream"
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'author.name()')" = "New Main Author"
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'author.email()')" = jj@example.com
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T change_id)" != "$previous"
      test "$(${customJj}/bin/jj file list --ignore-working-copy --revision "$previous")" = visible
      touch "$out"
    '';

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
