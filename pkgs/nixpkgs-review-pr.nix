{
  writeShellApplication,
  gh,
  gum,
  nixpkgs-review,
}:
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
