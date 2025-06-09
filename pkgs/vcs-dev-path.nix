{
  symlinkJoin,
  nixbits,
  # keep-sorted start
  gh,
  jj-fzf,
  jjui,
# keep-sorted end
}:
symlinkJoin {
  name = "vcs-dev-path";
  paths = [
    # keep-sorted start
    gh
    jj-fzf
    jjui
    nixbits.git
    nixbits.jujutsu
    nixbits.lazygit
    nixbits.lazyjj
    # keep-sorted end
  ];
  meta.description = "Favorite VCS development tools";
}
