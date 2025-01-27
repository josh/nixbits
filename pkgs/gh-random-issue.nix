{
  lib,
  stdenv,
  writeShellApplication,
  gh,
  xdg-utils,
  nixbits,
}:
writeShellApplication {
  name = "gh-random-issue";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath (
      [
        gh
        xdg-utils
      ]
      ++ (lib.lists.optionals stdenv.hostPlatform.isDarwin [ nixbits.darwin.open ])
    );
  };
  text = builtins.readFile ./gh-random-issue.bash;

  meta = {
    description = "Open a random GitHub issue.";
    platforms = lib.platforms.all;
  };
}
