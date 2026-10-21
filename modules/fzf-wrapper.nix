{
  config,
  lib,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.modules.default ];

  package = pkgs.fzf;
  wrapperImplementation = "nix";

  runShell = [
    ''
      case "''${THEME:-}" in
      ${
        lib.strings.concatMapStrings (
          t:
          if t.fzf == null then
            "${t.pattern}) ;;\n"
          else
            "${t.pattern}) export FZF_DEFAULT_OPTS=\"\${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--color=${t.fzf}\" ;;\n"
        ) pkgs.nixbits.themes
      }esac
    ''
  ];

  drv.meta.description = "Command-line fuzzy finder colored to match $THEME";

  passthru.tests = {
    version = pkgs.testers.testVersion {
      package = config.wrapper;
      command = "fzf --version";
      inherit (config.wrapper) version;
    };

    themes = pkgs.runCommand "test-fzf-themes" { } ''
      wrapper="${lib.getExe config.wrapper}"
      if ! grep --quiet --fixed-strings 'ansi_light) export FZF_DEFAULT_OPTS=' "$wrapper"; then
        echo "expected ansi_light to set FZF_DEFAULT_OPTS in $wrapper"
        return 1
      fi
      if ! grep --quiet --fixed-strings 'tokyonight_day) ;;' "$wrapper"; then
        echo "expected tokyonight_day to keep fzf defaults in $wrapper"
        return 1
      fi
      touch $out
    '';
  };
}
