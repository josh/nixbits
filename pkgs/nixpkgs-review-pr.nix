{
  writeShellApplication,
  gum,
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
    nixpkgs-review
  ];
  inheritPath = false;
  text = builtins.readFile ./nixpkgs-review-pr.bash;
  meta.description = "Review nixpkgs PRs";
}
