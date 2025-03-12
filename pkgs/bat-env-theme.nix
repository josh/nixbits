{
  lib,
  writeShellApplication,
  nixbits,
}:
let
  inherit (nixbits) bat;
  mkBatExe = theme: lib.getExe (bat.override { inherit theme; });
in
writeShellApplication {
  name = "bat";
  text = ''
    case "''${THEME:-}" in
    tokyonight_day)
      exec ${mkBatExe "tokyonight_day"} "$@"
      ;;
    tokyonight_moon)
      exec ${mkBatExe "tokyonight_moon"} "$@"
      ;;
    tokyonight_storm)
      exec ${mkBatExe "tokyonight_storm"} "$@"
      ;;
    tokyonight_night)
      exec ${mkBatExe "tokyonight_night"} "$@"
      ;;
    tokyonight*)
      exec ${mkBatExe "tokyonight_night"} "$@"
      ;;
    catppuccin_frappe)
      exec ${mkBatExe "catppuccin_frappe"} "$@"
      ;;
    catppuccin_latte)
      exec ${mkBatExe "catppuccin_latte"} "$@"
      ;;
    catppuccin_macchiato)
      exec ${mkBatExe "catppuccin_macchiato"} "$@"
      ;;
    catppuccin_mocha)
      exec ${mkBatExe "catppuccin_mocha"} "$@"
      ;;
    catppuccin*)
      exec ${mkBatExe "catppuccin_mocha"} "$@"
      ;;
    rosepine_moon)
      exec ${mkBatExe "rosepine_moon"} "$@"
      ;;
    rosepine_dawn)
      exec ${mkBatExe "rosepine_dawn"} "$@"
      ;;
    rosepine*)
      exec ${mkBatExe "rosepine"} "$@"
      ;;
    *)
      exec ${mkBatExe null} "$@"
      ;;
    esac
  '';
  meta = {
    inherit (bat.meta) description license platforms;
  };
}
