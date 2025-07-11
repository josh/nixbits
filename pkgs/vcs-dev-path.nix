{
  symlinkJoin,
  nixbits,
}:
symlinkJoin {
  name = "vcs-dev-path";
  paths = [
    # keep-sorted start
    nixbits.gh
    nixbits.git
    nixbits.jujutsu
    nixbits.lazygit
    nixbits.lazyjj
    # keep-sorted end
  ];
  meta.description = "Favorite VCS development tools";
}
