{
  lib,
  writeShellApplication,
  gh,
  xdg-utils,
}:
writeShellApplication {
  name = "gh-random-issue";
  runtimeInputs = [
    gh
    xdg-utils
  ];
  text = builtins.readFile ./gh-random-issue.bash;

  meta = {
    description = "Open a random GitHub issue.";
    platforms = lib.platforms.all;
  };
}
