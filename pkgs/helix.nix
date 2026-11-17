{
  wlibEvalPackage,
  helixConfig ? { },
}:
wlibEvalPackage [
  { settings = helixConfig; }
  ../modules/wrappers/helix.nix
]
