{
  lib,
  writeShellApplication,
  runCommand,
  coreutils,
  gnugrep,
  rsync,
  neovide,
}:
let
  script = writeShellApplication {
    name = "install-mac-app";
    runtimeInputs = [
      coreutils
      gnugrep
      rsync
    ];
    inheritPath = false;
    text = builtins.readFile ./install-mac-app.bash;
    meta = {
      description = "Copy macOS App into /Applications";
      platforms = lib.platforms.darwin;
    };
  };
in
script.overrideAttrs (_finalAttrs: {
  passthru.tests = {
    install-dry-run = runCommand "test-install-dry-run" { nativeBuildInputs = [ script ]; } ''
      mkdir -p "$TMPDIR/Applications"
      install-mac-app --dry-run --appdir "$TMPDIR/Applications" ${neovide}
      [ ! -d "$TMPDIR/Applications/Neovide.app" ]
      touch $out
    '';

    install-drv = runCommand "test-install-drv" { nativeBuildInputs = [ script ]; } ''
      mkdir -p "$TMPDIR/Applications"
      install-mac-app --appdir "$TMPDIR/Applications" ${neovide}
      [ -d "$TMPDIR/Applications/Neovide.app" ]
      [ ! -d "$TMPDIR/Applications/Neovide.app/Neovide.app" ]
      touch $out
    '';

    install-app = runCommand "test-install-app" { nativeBuildInputs = [ script ]; } ''
      mkdir -p "$TMPDIR/Applications"
      install-mac-app --appdir "$TMPDIR/Applications" ${neovide}/Applications/Neovide.app
      [ -d "$TMPDIR/Applications/Neovide.app" ]
      [ ! -d "$TMPDIR/Applications/Neovide.app/Neovide.app" ]
      touch $out
    '';

    install-logging = runCommand "test-install-logging" { nativeBuildInputs = [ script ]; } ''
      mkdir -p "$TMPDIR/Applications"
      if ! install-mac-app --appdir "$TMPDIR/Applications" ${neovide} 2>&1 | grep '+ rsync'; then
        echo "error: rsync command not logged"
        exit 1
      fi
      if install-mac-app --appdir "$TMPDIR/Applications" ${neovide} 2>&1 | grep '+ rsync'; then
        echo "error: rsync command logged"
        exit 1
      fi
      touch $out
    '';
  };
})
