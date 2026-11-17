{
  wlibEvalPackage,
  zellijTheme ? null,
}:
wlibEvalPackage [
  { inherit zellijTheme; }
  ../modules/wrappers/zellij.nix
]
