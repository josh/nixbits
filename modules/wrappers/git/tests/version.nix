{
  git,
  testers,
}:
testers.testVersion {
  package = git;
  command = "git version";
  inherit (git) version;
}
