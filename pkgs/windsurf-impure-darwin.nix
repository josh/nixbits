{
  lib,
  stdenvNoCC,
  runtimeShell,
  runCommandLocal,
}:
let
  app = "/Applications/Windsurf.app";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "windsurf-impure-darwin";
  version = "1.0.0";

  wrapper = ''
    #!${runtimeShell} -e
    exec "${app}/Contents/Resources/app/bin/windsurf" "$@"
  '';
  passAsFile = [ "wrapper" ];

  buildCommand = ''
    mkdir -p $out/bin
    install -m 755 $wrapperPath $out/bin/windsurf
  '';

  meta = {
    description = "Windsurf Command Line Tools";
    homepage = "https://codeium.com/windsurf";
    platforms = lib.platforms.darwin;
    mainProgram = "windsurf";
  };

  passthru.tests =
    let
      windsurf = finalAttrs.finalPackage;
    in
    {
      version =
        runCommandLocal "test-windsurf-version"
          {
            __impureHostDeps = [ app ];
            nativeBuildInputs = [ windsurf ];
          }
          ''
            if [ -d '${app}' ]; then
              windsurf --version
            else
              echo "WARN: Windsurf not installed" >&2
            fi
            touch $out
          '';
    };
})
