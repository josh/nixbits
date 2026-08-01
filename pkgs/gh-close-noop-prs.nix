{
  lib,
  writeShellApplication,
  nixbits,
  jq,
}:
let
  inherit (nixbits) gh;
in
writeShellApplication {
  name = "gh-close-noop-prs";
  runtimeInputs = [
    gh
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ./gh-close-noop-prs.bash;
  meta = {
    description = "Close noop PRs whose only failing check is lockfile-drv-changed";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
