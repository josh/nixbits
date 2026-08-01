{
  lib,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "launchd-exec";
  version = "0.1.0";

  __structuredAttrs = true;

  allowedReferences = [ ];

  buildCommand = ''
    substitute ${./launchd-exec.c} launchd-exec.c \
      --replace-fail '@version@' "$version"
    mkdir -p $out/bin
    $CC launchd-exec.c -o $out/bin/launchd-exec
  '';

  meta = {
    description = "Launchd exec permissions wrapper";
    license = lib.licenses.mit;
    mainProgram = "launchd-exec";
    platforms = lib.platforms.darwin;
  };
}
