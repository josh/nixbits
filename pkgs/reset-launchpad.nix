{
  lib,
  writeShellApplication,
  nixbits,
}:
writeShellApplication {
  name = "reset-launchpad";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      nixbits.darwin.defaults
      nixbits.darwin.killall
    ];
  };
  text = ''
    defaults write com.apple.dock ResetLaunchPad -bool true
    killall Dock
  '';
  meta = {
    description = "Reset Launchpad layout";
    platforms = lib.platforms.darwin;
  };
}
