{
  lib,
  writeShellApplication,
  coreutils,
  nix,
}:
writeShellApplication {
  name = "nix-profile-run-hooks";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      nix
    ];
  };
  text = builtins.readFile ./nix-profile-run-hooks.bash;

  meta.description = "Run hooks for nix profile";
}
