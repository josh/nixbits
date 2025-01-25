{
  lib,
  writeShellApplication,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "nix-profile-activate";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      nixbits.nix-profile-run-hooks
    ];
  };
  text = builtins.readFile ./nix-profile-activate.bash;

  meta.description = "Activate target nix profile";
}
