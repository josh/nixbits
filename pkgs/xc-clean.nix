{
  lib,
  writeShellApplication,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "xc-clean";
  runtimeInputs = [
    coreutils
    nixbits.darwin.xcrun
  ];
  inheritPath = false;
  text = builtins.readFile ./xc-clean.bash;
  meta = {
    description = "Clean up Xcode and simulator cache";
    platforms = lib.platforms.darwin;
  };
}
