{
  lib,
  runCommandLocal,
}:
let
  app = "/Applications/BBEdit.app";
  bbedit =
    runCommandLocal "bbedit-impure-darwin"
      {
        __impureHostDeps = [ app ];
        allowedReferences = [ ];
        allowedRequisites = [ ];

        meta = {
          description = "BBEdit Command Line Tools";
          mainProgram = "bbedit";
          platforms = lib.platforms.darwin;
        };

        passthru.tests = {
          help = runCommandLocal "test-bbedit-help" { nativeBuildInputs = [ bbedit ]; } ''
            if [ -d '${app}' ]; then
              bbedit --help
            else
              echo "WARN: BBEdit not installed" >&2
            fi
            touch $out
          '';
        };
      }
      ''
        mkdir -p $out/bin
        ln -s '${app}/Contents/Helpers/bbdiff' $out/bin/bbdiff
        ln -s '${app}/Contents/Helpers/bbedit_tool' $out/bin/bbedit
        ln -s '${app}/Contents/Helpers/bbfind' $out/bin/bbfind
        ln -s '${app}/Contents/Helpers/bbresults' $out/bin/bbresults

        mkdir -p $out/share/man/man1
        ln -s '${app}/Contents/Resources/bbdiff.1' $out/share/man/man1/bbdiff.1
        ln -s '${app}/Contents/Resources/bbedit.1' $out/share/man/man1/bbedit.1
        ln -s '${app}/Contents/Resources/bbfind.1' $out/share/man/man1/bbfind.1
        ln -s '${app}/Contents/Resources/bbresults.1' $out/share/man/man1/bbresults.1
      '';
in
bbedit
