{
  symlinkJoin,
  nixbits,
  # keep-sorted start
  cachix,
  deadnix,
  nh,
  nil,
  nix,
  nix-tree,
  nixd,
  nixfmt,
  nixpkgs-review,
  shellcheck,
  shfmt,
  statix,
  tree,
  # keep-sorted end
}:
symlinkJoin {
  name = "nix-dev-path";
  paths = [
    # keep-sorted start
    cachix
    deadnix
    nh
    nil
    nix
    nix-tree
    nixbits.gh
    nixbits.git
    nixbits.nix-check
    nixbits.nix-flake-diff-packages
    nixbits.nix-flake-rebuild
    nixbits.nix-flake-update-jj-main
    nixbits.nix-flake-update-jj-new
    nixbits.nix-profile-upgrade
    nixbits.nixpkgs-review-pr
    nixd
    nixfmt
    nixpkgs-review
    shellcheck
    shfmt
    statix
    tree
    # keep-sorted end
  ];
  meta.description = "Favorite nix development tools";
}
