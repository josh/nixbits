{
  wlibEvalPackage,
  herdr ? null,
}:
if herdr == null then { } else wlibEvalPackage ../modules/herdr-wrapper.nix
