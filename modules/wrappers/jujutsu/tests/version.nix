{
  testers,
  wlibEvalPackage,
}:
let
  jujutsu = wlibEvalPackage ../../jujutsu.nix;
in
testers.testVersion {
  package = jujutsu;
  command = "jj version";
  inherit (jujutsu) version;
}
