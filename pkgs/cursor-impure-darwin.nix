{
  lib,
  runCommandLocal,
}:
let
  app = "/Applications/Cursor.app";
  cursor =
    runCommandLocal "cursor-impure-darwin"
      {
        __impureHostDeps = [ app ];
        allowedReferences = [ ];
        allowedRequisites = [ ];

        meta = {
          description = "Cursor Command Line Tools";
          mainProgram = "cursor";
          platforms = lib.platforms.darwin;
        };

        passthru.tests = {
          help = runCommandLocal "test-cursor-help" { nativeBuildInputs = [ cursor ]; } ''
            if [ -d '${app}' ]; then
              cursor --help
            else
              echo "WARN: Cursor not installed" >&2
            fi
            touch $out
          '';
        };
      }
      ''
        mkdir -p $out/bin
        ln -s '${app}/Contents/Resources/app/bin/cursor' $out/bin/cursor
        ln -s '${app}/Contents/Resources/app/bin/code' $out/bin/code
      '';
in
cursor
