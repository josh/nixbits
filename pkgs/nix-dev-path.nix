{
  lib,
  symlinkJoin,
  # keep-sorted start
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
  nixbits,
}:
symlinkJoin {
  name = "nix-dev-path";
  paths = [
    # keep-sorted start
    (nixbits.nix-check.override { inherit nix; })
    (nixbits.nix-flake-diff-packages.override { inherit nix; })
    (nixbits.nix-flake-rebuild.override { inherit nix; })
    (nixbits.nix-flake-update-jj-main.override { inherit nix; })
    (nixbits.nix-flake-update-jj-new.override { inherit nix; })
    (nixbits.nix-profile-upgrade.override { inherit nix; })
    deadnix
    nh
    nil
    nix
    nix-tree
    nixbits.gh
    nixbits.git
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
  meta = {
    description = "Bundle of Nix development tools";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
