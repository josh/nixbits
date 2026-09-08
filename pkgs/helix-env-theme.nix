{
  wlibEvalPackage,
  helixConfig ? { },
}:
wlibEvalPackage [
  { settings = helixConfig; }
  ../modules/helix-env-theme-wrapper.nix
]
