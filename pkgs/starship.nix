{
  wlibEvalPackage,
  starshipConfig ? { },
}:
wlibEvalPackage [
  { settings = starshipConfig; }
  ../modules/wrappers/starship.nix
]
