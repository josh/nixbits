{
  lib,
  writeShellApplication,
  coreutils,
}:
writeShellApplication {
  name = "nix-profile-activate";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [ coreutils ];
  };
  text = builtins.readFile ./nix-profile-activate.bash;
}
