{
  lib,
  writeShellApplication,
  coreutils,
  findutils,
  nixbits,
}:
writeShellApplication {
  name = "launchctl-user-activate";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      findutils
      nixbits.launchctl-impure-darwin
    ];
  };
  text = builtins.readFile ./launchctl-user-activate.bash;
  meta = {
    mainProgram = "launchctl-user-activate";
    platforms = lib.platforms.darwin;
  };
}
