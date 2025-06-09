{
  symlinkJoin,
  nixbits,
  # keep-sorted start
  cachix,
  deadnix,
  fh,
  gh,
  nh,
  nil,
  nix,
  nix-tree,
  nixd,
  nixfmt-rfc-style,
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
    fh
    gh
    nh
    nil
    nix
    nix-tree
    nixbits.git
    nixbits.nix-flake-diff-packages
    nixbits.nix-flake-rebuild
    nixbits.nix-profile-upgrade
    nixbits.nixpkgs-review-pr
    nixd
    nixfmt-rfc-style
    nixpkgs-review
    shellcheck
    shfmt
    statix
    tree
    # keep-sorted end
  ];
  meta.description = "Favorite nix development tools";
}
