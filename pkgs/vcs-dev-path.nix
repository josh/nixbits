{
  symlinkJoin,
  pkgs,
  nixbits,
}:
let
  nixpkgs = pkgs;
in
symlinkJoin {
  name = "vcs-dev-path";
  paths = [
    # keep-sorted start
    nixbits.git
    nixbits.jujutsu
    nixbits.lazygit
    nixbits.lazyjj
    nixpkgs.gh
    nixpkgs.jj-fzf
    nixpkgs.jjui
    # keep-sorted end
  ];
  meta.description = "Favorite VCS development tools";
}
