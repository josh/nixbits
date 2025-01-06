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

        meta = {
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
        ln -s '${app}/Contents/Helpers/bbdiff' $out/bin
        ln -s '${app}/Contents/Helpers/bbedit_tool' $out/bin/bbedit
        ln -s '${app}/Contents/Helpers/bbfind' $out/bin
        ln -s '${app}/Contents/Helpers/bbresults' $out/bin

        mkdir -p $out/share/man/man1
        ln -s '${app}/Contents/Resources/bbdiff.1' $out/share/man/man1
        ln -s '${app}/Contents/Resources/bbedit.1' $out/share/man/man1
        ln -s '${app}/Contents/Resources/bbfind.1' $out/share/man/man1
        ln -s '${app}/Contents/Resources/bbresults.1' $out/share/man/man1
      '';
in
bbedit