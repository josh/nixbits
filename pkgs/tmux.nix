{
  wlibEvalPackage,
  bash,
  interactiveShell ? "${bash}/bin/bash",
  theme ? null,
}:
wlibEvalPackage [
  {
    shell = interactiveShell;
    inherit theme;
  }
  ../modules/tmux-wrapper.nix
]
