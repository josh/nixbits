{
  lib,
  writeShellApplication,
  runCommand,
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
    ${lib.strings.concatMapStrings (t: ''
      ${t.pattern})
        exec ${mkBatExe t.bat} "$@"
        ;;
    '') nixbits.themes}
    *)
      exec ${mkBatExe null} "$@"
      ;;
    esac
  '';
  passthru.tests.themes = runCommand "test-bat-env-theme" { } ''
    for case in "tokyonight_bogus:Tokyo Night Night" "rosepine_moon:Rose Pine Moon" \
                "ansi_light:ansi" "ansi_dark:ansi"; do
      theme="''${case%%:*}"
      expected="''${case#*:}"
      actual="$(THEME="$theme" ${lib.getExe nixbits.bat-env-theme} --diagnostic | sed -n 's/^BAT_THEME=//p' | tr -d "'")"
      if [[ "$actual" != "$expected" ]]; then
        echo "THEME=$theme expected '$expected' but was '$actual'"
        return 1
      fi
    done
    touch $out
  '';
  meta = {
    inherit (bat.meta) description license platforms;
    mainProgram = "bat";
  };
}
