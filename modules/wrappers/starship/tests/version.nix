{ starship, testers }:
testers.testVersion {
  package = starship;
  command = "starship --version";
  inherit (starship) version;
}
