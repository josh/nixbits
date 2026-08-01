{
  lib,
  writeShellApplication,
  nixbits,
  helix,
  helixConfig ? { },
}:
let
  mkHelix =
    theme:
    let
      themeAttrs = lib.attrsets.optionalAttrs (theme != null) { inherit theme; };
      helixConfig' = helixConfig // themeAttrs;
    in
    nixbits.helix.override {
      inherit helix;
      helixConfig = helixConfig';
    };
  mkHelixExe = theme: lib.getExe (mkHelix theme);
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
    # The wrapper may swap the helix argument for evil-helix; describe the
    # package that is actually executed.
    inherit ((mkHelix null).meta)
      description
      license
      ;
    mainProgram = "hx";
    platforms = lib.platforms.all;
  };
}
