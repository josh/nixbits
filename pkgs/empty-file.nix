{
  lib,
  stdenv,
  coreutils,
}:
derivation {
  inherit (stdenv.hostPlatform) system;
  name = "empty-file";
  builder = "${coreutils}/bin/touch";
  args = [ (builtins.placeholder "out") ];

  allowedReferences = [ ];
  allowedRequisites = [ ];

  outputHash = "sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=";
  outputHashAlgo = "sha256";
  outputHashMode = "flat";
}
// {
  meta = {
    description = "Empty file";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
