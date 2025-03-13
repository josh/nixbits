{
  lib,
  stdenvNoCC,
  writeShellScript,
  runCommandLocal,
}:
let
  app = "/Applications/BBEdit.app";
  bbeditHelper =
    name:
    writeShellScript name ''
      exec "${app}/Contents/Helpers/${name}" "$@"
    '';
  preinstallHook = writeShellScript "bbedit-mas-preinstall-hook" ''
    if [ ! -d "/Applications/BBEdit.app" ]; then
      echo "warn: BBEdit is not installed" >&2
      echo "  https://www.barebones.com/products/bbedit/" >&2
    fi
  '';
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "bbedit-mas";

  buildCommand = ''
    mkdir -p $out/bin $out/share/nix/hooks/pre-install.d $out/share/mas
    install -m 755 ${bbeditHelper "bbedit_tool"} $out/bin/bbedit
    install -m 755 ${bbeditHelper "bbdiff"} $out/bin/bbdiff
    install -m 755 ${bbeditHelper "bbfind"} $out/bin/bbfind
    install -m 755 ${bbeditHelper "bbresults"} $out/bin/bbresults
    install -m 755 ${preinstallHook} $out/share/nix/hooks/pre-install.d/bbedit
    echo "BBEdit" >$out/share/mas/404009241
  '';

  passthru.tests =
    let
      bbedit = finalAttrs.finalPackage;
    in
    {
      version =
        runCommandLocal "test-bbedit-version"
          {
            __impureHostDeps = [ app ];
            nativeBuildInputs = [ bbedit ];
          }
          ''
            if [ -d '${app}' ]; then
              bbedit --version
            fi
            touch $out
          '';
    };

  meta = {
    description = "BBEdit Command Line Tools";
    homepage = "https://www.barebones.com/products/bbedit/";
    platforms = lib.platforms.darwin;
    mainProgram = "bbedit";
  };
})
