{
  lib,
  writeShellApplication,
  curl,
  jq,
}:
writeShellApplication {
  name = "trakt-id-from-url";
  runtimeEnv = {
    PATH = lib.makeBinPath [
      curl
      jq
    ];
  };
  text = builtins.readFile ./trakt-id-from-url.bash;
  meta = {
    description = "Extract Trakt media ID from URL";
    platforms = lib.platforms.all;
  };
}
