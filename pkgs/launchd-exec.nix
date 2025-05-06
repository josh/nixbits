{
  lib,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "launchd-exec";
  version = "0.1.0";

  buildCommand = ''
    substitute ${./launchd-exec.c} launchd-exec.c \
      --replace-fail '@version@' "$version"
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
