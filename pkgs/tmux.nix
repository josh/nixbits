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
  ../modules/wrappers/tmux.nix
]
