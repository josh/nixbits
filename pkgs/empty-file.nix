{
  system,
  lib,
  coreutils,
}:
derivation {
  inherit system;
  name = "empty";
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
    description = "An empty file";
    platforms = lib.platforms.all;
    available = true;
  };
}
