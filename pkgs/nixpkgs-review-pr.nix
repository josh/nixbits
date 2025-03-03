{
  lib,
  writeShellApplication,
  nixpkgs-review,
}:
writeShellApplication {
  name = "nixpkgs-review-pr";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      nixpkgs-review
    ];
  };
  text = builtins.readFile ./nixpkgs-review-pr.bash;
  meta.description = "Review nixpkgs PRs";
}
