{
  lib,
  stdenvNoCC,
  runtimeShell,
  runCommandLocal,
}:
let
  app = "/Applications/Cursor.app";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "cursor-cli";

  __structuredAttrs = true;

  wrapper = ''
    #!${runtimeShell} -e
    exec "${app}/Contents/Resources/app/bin/cursor" "$@"
  '';
  preInstallHook = ''
    #!${runtimeShell} -e
    if [ ! -d '${app}' ]; then
      echo "WARN: Cursor not installed" >&2
      echo "  https://www.cursor.com" >&2
    fi
  '';

  buildCommand = ''
    mkdir -p $out/bin $out/share/nix/hooks/pre-install.d
    echo "$wrapper" >$out/bin/cursor
    chmod +x $out/bin/cursor
    echo "$preInstallHook" >$out/share/nix/hooks/pre-install.d/cursor
    chmod +x $out/share/nix/hooks/pre-install.d/cursor
  '';

  passthru.tests =
    let
      cursor = finalAttrs.finalPackage;
    in
    {
      version =
        runCommandLocal "test-cursor-version"
          {
            __impureHostDeps = [ app ];
            nativeBuildInputs = [ cursor ];
          }
          ''
            if [ -d '${app}' ]; then
              cursor --version
            fi
            touch $out
          '';
    };

  meta = {
    description = "Cursor Command Line Tools";
    homepage = "https://www.cursor.com";
    platforms = lib.platforms.darwin;
    mainProgram = "cursor";
  };
})
