{
  lib,
  writeShellApplication,
  curl,
  jq,
}:
writeShellApplication {
  name = "trakt-id-from-url";
  runtimeInputs = [
    curl
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ./trakt-id-from-url.bash;
  meta = {
    description = "Extract Trakt media ID from URL";
    platforms = lib.platforms.all;
  };
}
