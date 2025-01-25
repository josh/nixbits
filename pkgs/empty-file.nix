{
  system,
  lib,
  coreutils,
}:
derivation {
  inherit system;
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
    name = "empty-file";
    description = "An empty file";
    platforms = lib.platforms.all;
    available = true;
  };
}
