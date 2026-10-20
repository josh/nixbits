{
  config,
  lib,
  pkgs,
  wlib,
  ...
}:
let
  themes = map (t: {
    inherit (t) pattern;
    theme = t.helix;
  }) pkgs.nixbits.themes;

  configDir = name: "${placeholder config.outputName}/${config.binName}-config-${name}";

  mkConfig = name: settings: {
    relPath = "${config.binName}-config-${name}/helix/config.toml";
    content = builtins.toJSON settings;
    builder = ''${pkgs.remarshal}/bin/json2toml "$1" "$2"'';
  };
in
{
  imports = [ wlib.modules.default ];

  options.settings = lib.mkOption {
    type = wlib.types.structuredValueWith {
      nullable = false;
      typeName = "TOML";
    };
    default = { };
    description = ''
      Base helix configuration, merged with the theme selected by `$THEME`.
      See <https://docs.helix-editor.com/configuration.html>
    '';
  };

  config = {
    package = pkgs.helix;
    binName = "hx";
    wrapperImplementation = "nix";

    constructFiles = builtins.listToAttrs (
      [ (lib.attrsets.nameValuePair "default" (mkConfig "default" config.settings)) ]
      ++ map (
        t: lib.attrsets.nameValuePair t.theme (mkConfig t.theme (config.settings // { inherit (t) theme; }))
      ) themes
    );

    passthru.tests.themes =
      pkgs.runCommand "test-helix-env-theme" { nativeBuildInputs = [ config.wrapper ]; }
        ''
          export HOME="$PWD"
          for case in tokyonight_moon:tokyonight_moon tokyonight_bogus:tokyonight \
                      catppuccin_bogus:catppuccin_mocha rosepine_moon:rose_pine_moon \
                      ansi_light:term16_light ansi_dark:term16_dark; do
            theme="''${case%%:*}"
            expected="''${case##*:}"
            actual="$(THEME="$theme" hx --health | sed -n '1s|.*/hx-config-\(.*\)/helix/config.toml|\1|p')"
            if [[ "$actual" != "$expected" ]]; then
              echo "THEME=$theme expected '$expected' but was '$actual'"
              return 1
            fi
          done
          touch $out
        '';

    runShell = [
      ''
        case "''${THEME:-}" in
        ${lib.strings.concatMapStringsSep "\n" (
          t: "${t.pattern}) export XDG_CONFIG_HOME=${lib.escapeShellArg (configDir t.theme)} ;;"
        ) themes}
        *) export XDG_CONFIG_HOME=${lib.escapeShellArg (configDir "default")} ;;
        esac
      ''
    ];
  };
}
