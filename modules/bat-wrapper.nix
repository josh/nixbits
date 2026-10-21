{
  config,
  lib,
  pkgs,
  wlib,
  ...
}:
let
  inherit (pkgs) nixbits;

  builtinThemes = [ "ansi" ];

  tmthemes = map (theme: nixbits.tmtheme.override { inherit theme; }) (
    lib.lists.unique (
      builtins.filter (theme: !(builtins.elem theme builtinThemes)) (map (t: t.bat) nixbits.themes)
    )
  );

  themeName =
    theme:
    if builtins.elem theme builtinThemes then
      theme
    else
      (nixbits.tmtheme.override { inherit theme; }).themeName;

  batDir = pkgs.runCommand "bat-config" { nativeBuildInputs = [ pkgs.bat ]; } ''
    mkdir -p $out/etc/bat/themes $out/var/cache/bat
    touch $out/etc/bat/config
    ${lib.strings.concatMapStrings (tmtheme: ''
      ln -s ${tmtheme} "$out/etc/bat/themes/${tmtheme.themeName}.tmTheme"
    '') tmthemes}
    BAT_CONFIG_DIR=$out/etc/bat BAT_CACHE_PATH=$out/var/cache/bat bat cache --build
    sed -i 's/secs_since_epoch: [0-9]*/secs_since_epoch: 0/' $out/var/cache/bat/metadata.yaml
    sed -i 's/nanos_since_epoch: [0-9]*/nanos_since_epoch: 0/' $out/var/cache/bat/metadata.yaml
  '';
in
{
  imports = [ wlib.modules.default ];

  package = pkgs.bat;
  wrapperImplementation = "nix";

  env = {
    BAT_CONFIG_DIR = "${batDir}/etc/bat";
    BAT_CONFIG_PATH = "${batDir}/etc/bat/config";
    BAT_CACHE_PATH = "${batDir}/var/cache/bat";
  };

  runShell = [
    ''
      case "''${THEME:-}" in
      ${
        lib.strings.concatMapStrings (
          t: "${t.pattern}) export BAT_THEME=${lib.escapeShellArg (themeName t.bat)} ;;\n"
        ) nixbits.themes
      }esac
    ''
  ];

  drv.meta.description = "Cat clone with syntax highlighting themed by $THEME";

  passthru.tests = {
    version = pkgs.testers.testVersion {
      package = config.wrapper;
      command = "bat --version";
      inherit (config.wrapper) version;
    };

    themes = pkgs.runCommand "test-bat-themes" { nativeBuildInputs = [ config.wrapper ]; } ''
      for case in "tokyonight_bogus:Tokyo Night Night" "rosepine_moon:Rose Pine Moon" \
                  "ansi_light:ansi" "ansi_dark:ansi"; do
        theme="''${case%%:*}"
        expected="''${case#*:}"
        actual="$(THEME="$theme" bat --diagnostic | sed -n 's/^BAT_THEME=//p' | tr -d "'")"
        if [[ "$actual" != "$expected" ]]; then
          echo "THEME=$theme expected '$expected' but was '$actual'"
          return 1
        fi
        if ! THEME="$theme" bat --color=always --plain ${./bat-wrapper.nix} >/dev/null; then
          echo "THEME=$theme failed to render"
          return 1
        fi
      done
      touch $out
    '';
  };
}
