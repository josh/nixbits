{
  symlinkJoin,
  pkgs,
  nixbits,
}:
let
  nixpkgs = pkgs;
in
symlinkJoin {
  name = "nix-dev-path";
  paths = [
    # keep-sorted start
    nixbits.git
    nixbits.nix-flake-diff-packages
    nixbits.nix-flake-rebuild
    nixbits.nix-profile-upgrade
    nixbits.nixpkgs-review-pr
    nixpkgs.cachix
    nixpkgs.deadnix
    nixpkgs.fh
    nixpkgs.gh
    nixpkgs.nh
    nixpkgs.nil
    nixpkgs.nix
    nixpkgs.nixd
    nixpkgs.nixfmt-rfc-style
    nixpkgs.nixpkgs-review
    nixpkgs.shellcheck
    nixpkgs.shfmt
    nixpkgs.statix
    nixpkgs.tree
    # keep-sorted end
  ];
  meta.description = "Favorite nix development tools";
}
