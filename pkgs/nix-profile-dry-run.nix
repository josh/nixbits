{
  lib,
  writeShellApplication,
  coreutils,
  nix,
}:
writeShellApplication {
  name = "nix-profile-dry-run";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      nix
    ];
  };
  text = builtins.readFile ./nix-profile-dry-run.bash;
}
