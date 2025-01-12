{
  lib,
  writeShellApplication,
  coreutils,
  nix,
  jq,
}:
writeShellApplication {
  name = "nix-flake-rebuild";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      nix
      jq
    ];
  };
  text = builtins.readFile ./nix-flake-rebuild.bash;

  meta.description = "Rebuild all packages in current nix flake";
}
