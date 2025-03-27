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
    runtimeEnv = {
      PATH = lib.strings.makeBinPath [
        coreutils
        gnugrep
        rsync
      ];
    };
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

    install-twice = runCommand "test-install-twice" { nativeBuildInputs = [ script ]; } ''
      mkdir -p "$TMPDIR/Applications"
      install-mac-app --appdir "$TMPDIR/Applications" ${neovide}
      [ -d "$TMPDIR/Applications/Neovide.app" ]
      install-mac-app --appdir "$TMPDIR/Applications" ${neovide}
      touch $out
    '';
  };
})
