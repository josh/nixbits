{
  lib,
  writeShellApplication,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "launchctl-activate";
  runtimeEnv = {
    PATH = lib.makeBinPath [
      coreutils
      nixbits.launchctl-impure-darwin
    ];
  };
  text = builtins.readFile ./launchctl-user-activate.bash;
}
