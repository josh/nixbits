{
  wlibEvalPackage,
  herdr ? null,
}:
if herdr == null then { } else wlibEvalPackage ../modules/wrappers/herdr.nix
