{
  wlibEvalPackage,
  helixConfig ? { },
}:
wlibEvalPackage [
  { settings = helixConfig; }
  ../modules/wrappers/helix-env-theme.nix
]
