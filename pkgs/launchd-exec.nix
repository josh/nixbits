{
  lib,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "launchd-exec";
  version = "0.1.0";

  buildCommand = ''
    substituteAll ${./launchd-exec.c} launchd-exec.c
    mkdir -p $out/bin
    $CC launchd-exec.c -o $out/bin/launchd-exec
  '';

  allowedReferences = [ ];

  meta = {
    description = "launchd exec permissions wrapper";
    mainProgram = "launchd-exec";
    platforms = lib.platforms.darwin;
  };
}
