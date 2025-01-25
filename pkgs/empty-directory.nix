{
  system,
  lib,
  coreutils,
}:
derivation {
  inherit system;
  name = "empty-directory";
  builder = "${coreutils}/bin/mkdir";
  args = [ (builtins.placeholder "out") ];

  allowedReferences = [ ];
  allowedRequisites = [ ];

  outputHash = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
}
// {
  meta = {
    name = "empty-directory";
    description = "An empty directory";
    platforms = lib.platforms.all;
    available = true;
  };
}
