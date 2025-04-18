{
  lib,
  writeShellApplication,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "xc-clean";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      nixbits.darwin.xcrun
    ];
  };
  text = builtins.readFile ./xc-clean.bash;
  meta = {
    description = "Clean up Xcode and simulator cache";
    platforms = lib.platforms.darwin;
  };
}
