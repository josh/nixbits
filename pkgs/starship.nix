{
  wlibEvalPackage,
  starshipConfig ? { },
}:
wlibEvalPackage [
  { settings = starshipConfig; }
  ../modules/starship-wrapper.nix
]
