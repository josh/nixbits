{
  lib,
  runCommandLocal,
}:
let
  app = "/Applications/Zed.app";
  zed =
    runCommandLocal "zed-impure-darwin"
      {
        __impureHostDeps = [ app ];

        meta = {
          mainProgram = "zed";
          platforms = lib.platforms.darwin;
        };

        passthru.tests = {
          help = runCommandLocal "test-zed-help" { nativeBuildInputs = [ zed ]; } ''
            if [ -d '${app}' ]; then
              zed --help
            else
              echo "WARN: Zed not installed" >&2
            fi
            touch $out
          '';
        };
      }
      ''
        mkdir -p $out/bin
        ln -s '${app}/Contents/MacOS/cli' $out/bin/zed
      '';
in
zed