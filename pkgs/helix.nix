{
  wlibEvalPackage,
  helixConfig ? { },
}:
wlibEvalPackage [
  { settings = helixConfig; }
  ../modules/helix-wrapper.nix
]
