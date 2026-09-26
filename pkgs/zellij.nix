{
  wlibEvalPackage,
  zellijTheme ? null,
}:
wlibEvalPackage [
  { inherit zellijTheme; }
  ../modules/zellij-wrapper.nix
]
