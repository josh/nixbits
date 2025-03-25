{
  lib,
  stdenv,
  writeShellApplication,
  coreutils,
  gh,
  jq,
  nixbits,
}:
writeShellApplication {
  name = "gh-dependabot";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath (
      [
        coreutils
        gh
        jq
      ]
      ++ (lib.lists.optional stdenv.hostPlatform.isDarwin nixbits.darwin.open)
    );
  };
  text = builtins.readFile ./gh-dependabot.bash;
  meta = {
    description = "Open GitHub Insights -> Dependency graph -> Dependabot page";
    platforms = lib.platforms.all;
  };
}
