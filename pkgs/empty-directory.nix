{
  system,
  lib,
  coreutils,
}:
derivation {
  inherit system;
  name = "empty";
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
    description = "An empty directory";
    platforms = lib.platforms.all;
    available = true;
  };
}