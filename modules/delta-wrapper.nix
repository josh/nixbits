{
  config,
  pkgs,
  wlib,
  ...
}:
let
  inherit (pkgs.nixbits) bat;
in
{
  imports = [ wlib.modules.default ];

  package = pkgs.delta;
  wrapperImplementation = "nix";

  env.XDG_CACHE_HOME = builtins.dirOf bat.configuration.env.BAT_CACHE_PATH.data;

  inherit (bat.configuration) runShell;

  drv.meta.description = "Syntax-highlighting diff pager themed by $THEME";

  passthru.tests = {
    version = pkgs.testers.testVersion {
      package = config.wrapper;
      command = "delta --version";
      inherit (config.wrapper) version;
    };

    themes = pkgs.runCommand "test-delta-themes" { nativeBuildInputs = [ config.wrapper ]; } ''
      for theme in tokyonight_day tokyonight_moon tokyonight_storm tokyonight_bogus \
                   catppuccin_frappe catppuccin_latte catppuccin_macchiato catppuccin_bogus \
                   rosepine_moon rosepine_dawn rosepine_bogus ansi_light ansi_dark; do
        if THEME="$theme" delta --show-config </dev/null 2>&1 | grep --quiet "Unknown theme"; then
          echo "THEME=$theme selected a theme delta does not know"
          return 1
        fi
      done
      touch $out
    '';
  };
}
