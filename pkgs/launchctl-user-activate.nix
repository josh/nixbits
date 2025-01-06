{
  lib,
  writeShellApplication,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "launchctl-user-activate";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      nixbits.launchctl-impure-darwin
    ];
  };
  text = builtins.readFile ./launchctl-user-activate.bash;
  meta = {
    mainProgram = "launchctl-user-activate";
    platforms = lib.platforms.darwin;
  };
}
