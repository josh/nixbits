{
  lib,
  writeShellApplication,
  coreutils,
  nix,
  jq,
}:
writeShellApplication {
  name = "nix-flake-check-size";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      nix
      jq
    ];
  };
  text = builtins.readFile ./nix-flake-check-size.bash;
  meta = {
    description = "Check NAR size of flake checks";
    platforms = lib.platforms.all;
  };
}
