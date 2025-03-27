{
  lib,
  writeShellApplication,
  coreutils,
  gnugrep,
  rsync,
  nixbits,
}:
writeShellApplication {
  name = "install-mac-app";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      gnugrep
      rsync
      nixbits.darwin.codesign
    ];
  };
  text = builtins.readFile ./install-mac-app.bash;
  meta = {
    description = "Copy macOS App into /Applications";
    platforms = lib.platforms.darwin;
  };
}
