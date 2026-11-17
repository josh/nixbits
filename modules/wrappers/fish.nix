{
  config,
  lib,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.wrapperModules.fish ];

  options.fishConfig = lib.mkOption {
    type = lib.types.package;
    default = pkgs.nixbits.fish-config;
    description = "Directory with the config.fish and conf.d files sourced at startup.";
  };

  config = {
    flags."--no-config" = false;
    configFile.content = "source ${config.fishConfig}/config.fish";

    passthru.tests = {
      version = pkgs.testers.testVersion {
        package = config.wrapper;
        command = "fish --version";
        inherit (config.wrapper) version;
      };

      themes = pkgs.runCommand "test-fish-themes" { nativeBuildInputs = [ config.wrapper ]; } ''
        export HOME="$PWD"
        themed="$(THEME=tokyonight_bogus fish -c 'echo $fish_color_command')"
        if [ -z "$themed" ]; then
          echo "expected THEME=tokyonight_bogus to set fish colors"
          return 1
        fi
        plain="$(THEME=ansi_dark fish -c 'echo $fish_color_command')"
        if [ -n "$plain" ]; then
          echo "expected THEME=ansi_dark to keep fish defaults but was '$plain'"
          return 1
        fi
        touch $out
      '';
    };
  };
}
