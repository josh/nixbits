{
  lib,
  writeShellApplication,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "launchctl-activate";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      nixbits.launchctl-impure-darwin
    ];
  };
  text = builtins.readFile ./launchctl-user-activate.bash;
}
