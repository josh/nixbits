{
  lib,
  runCommandLocal,
}:
let
  app = "/Applications/Windsurf.app";
  windsurf =
    runCommandLocal "windsurf-impure-darwin"
      {
        __impureHostDeps = [ app ];

        meta = {
          description = "Windsurf Command Line Tools";
          mainProgram = "windsurf";
          platforms = lib.platforms.darwin;
        };

        passthru.tests = {
          help = runCommandLocal "test-windsurf-help" { nativeBuildInputs = [ windsurf ]; } ''
            if [ -d '${app}' ]; then
              windsurf --help
            else
              echo "WARN: Windsurf not installed" >&2
            fi
            touch $out
          '';
        };
      }
      ''
        mkdir -p $out/bin
        ln -s '${app}/Contents/Resources/app/bin/windsurf' $out/bin/windsurf
      '';
in
windsurf
