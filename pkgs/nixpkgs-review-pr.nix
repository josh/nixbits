{
  lib,
  writeShellApplication,
  gum,
  nix,
  nixpkgs-review,
  nixbits,
}:
let
  inherit (nixbits) gh;
in
writeShellApplication {
  name = "nixpkgs-review-pr";
  runtimeInputs = [
    gh
    gum
    (nixpkgs-review.override { inherit nix; })
  ];
  inheritPath = false;
  text = builtins.readFile ./nixpkgs-review-pr.bash;
  meta = {
    description = "Review nixpkgs PRs";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
