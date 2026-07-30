_final: prev:
if !(prev ? lib && prev ? stdenv) then
  { }
else
  let
    inherit (prev) lib;
    inherit (prev.stdenv.hostPlatform) system;

    isRelease2605 = lib.trivial.release == "26.05";
    isUnstable = lib.trivial.release == "26.11";

    # markBroken =
    #   drv:
    #   drv.overrideAttrs (
    #     {
    #       meta ? { },
    #       ...
    #     }:
    #     {
    #       meta = meta // {
    #         broken = true;
    #       };
    #     }
    #   );
  in
  if isRelease2605 && system == "x86_64-linux" then
    { }
  else if isRelease2605 && system == "aarch64-linux" then
    { }
  else if isRelease2605 && system == "aarch64-darwin" then
    { }
  else if isUnstable && system == "x86_64-linux" then
    { }
  else if isUnstable && system == "aarch64-linux" then
    { }
  else if isUnstable && system == "aarch64-darwin" then
    { }
  else
    { }
