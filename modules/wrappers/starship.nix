{
  config,
  lib,
  pkgs,
  wlib,
  ...
}:
let
  jjConfiguration = config.jujutsuWrapper.configuration;
  jj = lib.getExe' jjConfiguration.jujutsuPackage "jj";
in
{
  imports = [ wlib.wrapperModules.starship ];

  options.showJujutsuDescription = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to show the first line of the working-copy change description in the prompt.";
  };

  options.jujutsuWrapper = lib.mkOption {
    type = lib.types.package;
    default = pkgs.nixbits.jujutsu;
    description = "JJ wrapper supplying the executable and configuration for the prompt.";
  };

  config = {
    wrapperImplementation = "binary";
    # Init resolves starship on PATH for its hooks, and native JJ modules resolve jj.
    prefixVar = [
      [
        "PATH"
        ":"
        "${placeholder "out"}/bin:${lib.getBin jjConfiguration.jujutsuPackage}/bin"
      ]
    ];
    env = {
      JJ_CONFIG = jjConfiguration.env.JJ_CONFIG.data;
      GIT_CONFIG_GLOBAL = jjConfiguration.env.GIT_CONFIG_GLOBAL.data;
    };
    drv.meta.broken = lib.versionOlder config.package.version "1.27.0";

    settings = {
      format = lib.mkDefault "$all";
      vcs.order = lib.mkDefault [
        "jj"
        "git"
      ];
      custom.jj_description = lib.mkIf config.showJujutsuDescription {
        when = true;
        shell = [ pkgs.runtimeShell ];
        command = "${jj} log --ignore-working-copy --no-graph -r @ -T 'description.first_line()' 2>/dev/null";
        style = "blue";
        format = "([$output]($style) )";
      };
    };

    buildCommand.expandPromptFormat = lib.mkIf (config.settings.format == "$all") {
      after = [ "constructFiles" ];
      data = ''
        # Starship prints the expanded $all order in a comment.
        format=$(${config.package}/bin/starship print-config --default format |
          sed -n 's/^# \$all is shorthand for //p')
        gitModules='$git_branch$git_commit$git_state$git_metrics$git_status'
        substituteInPlace "$out/starship.toml" \
          --replace-fail 'format = "$all"' "format = \"$format\"" \
          --replace-fail "$gitModules" '$vcs${lib.optionalString config.showJujutsuDescription "\${custom.jj_description}"}'
      '';
    };

    passthru.tests = lib.filesystem.packagesFromDirectoryRecursive {
      callPackage = pkgs.newScope { starship = config.wrapper; };
      directory = ./starship/tests;
    };
  };
}
