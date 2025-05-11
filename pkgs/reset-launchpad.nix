{
  lib,
  writeShellApplication,
  nixbits,
}:
writeShellApplication {
  name = "reset-launchpad";
  runtimeInputs = [
    nixbits.darwin.defaults
    nixbits.darwin.killall
  ];
  inheritPath = false;
  text = ''
    defaults write com.apple.dock ResetLaunchPad -bool true
    killall Dock
  '';
  meta = {
    description = "Reset Launchpad layout";
    platforms = lib.platforms.darwin;
  };
}
