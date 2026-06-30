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
    description = "Close my open PRs labeled noop whose only failing check is lockfile-drv-changed";
    platforms = lib.platforms.all;
  };
}
