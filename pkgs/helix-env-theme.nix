{
  lib,
  writeShellApplication,
  nixbits,
  helix,
  helixConfig ? { },
}:
let
  mkHelixExe =
    theme:
    let
      themeAttrs = lib.optionalAttrs (theme != null) { inherit theme; };
      helixConfig' = helixConfig // themeAttrs;
    in
    lib.getExe (
      nixbits.helix.override {
        inherit helix;
        helixConfig = helixConfig';
      }
    );
in
writeShellApplication {
  name = "hx";
  text = ''
    case "''${THEME:-}" in
    tokyonight_day)
      exec ${mkHelixExe "tokyonight_day"} "$@"
      ;;
    tokyonight_moon)
      exec ${mkHelixExe "tokyonight_moon"} "$@"
      ;;
    tokyonight_storm)
      exec ${mkHelixExe "tokyonight_storm"} "$@"
      ;;
    tokyonight_night)
      exec ${mkHelixExe "tokyonight"} "$@"
      ;;
    tokyonight*)
      exec ${mkHelixExe "tokyonight"} "$@"
      ;;
    catppuccin_frappe)
      exec ${mkHelixExe "catppuccin_frappe"} "$@"
      ;;
    catppuccin_latte)
      exec ${mkHelixExe "catppuccin_latte"} "$@"
      ;;
    catppuccin_macchiato)
      exec ${mkHelixExe "catppuccin_macchiato"} "$@"
      ;;
    catppuccin_mocha)
      exec ${mkHelixExe "catppuccin_mocha"} "$@"
      ;;
    catppuccin*)
      exec ${mkHelixExe "catppuccin_mocha"} "$@"
      ;;
    rosepine_moon)
      exec ${mkHelixExe "rose_pine_moon"} "$@"
      ;;
    rosepine_dawn)
      exec ${mkHelixExe "rose_pine_dawn"} "$@"
      ;;
    rosepine*)
      exec ${mkHelixExe "rose_pine"} "$@"
      ;;
    *)
      exec ${mkHelixExe null} "$@"
      ;;
    esac
  '';
  meta = {
    inherit (helix.meta)
      description
      license
      platforms
      ;
  };
}
