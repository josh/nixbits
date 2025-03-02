{
  lib,
  writeShellApplication,
  jd-diff-patch,
  nix,
}:
writeShellApplication {
  name = "nix-flake-diff-packages";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      jd-diff-patch
      nix
    ];
  };
  text = builtins.readFile ./nix-flake-diff-packages.bash;
  meta = {
    description = "Compare the package outputs of 2 nix flakes";
    platforms = lib.platforms.all;
  };
}
