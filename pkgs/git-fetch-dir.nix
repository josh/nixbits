{
  lib,
  writeShellApplication,
  git,
  findutils,
}:
let
  git-fetch-git-dir = writeShellApplication {
    name = "git-fetch-git-dir";
    runtimeInputs = [ git ];
    inheritPath = false;
    text = ''
      set -x
      git --git-dir="$1" fetch --all --quiet
    '';
  };
in
writeShellApplication {
  name = "git-fetch-dir";
  runtimeInputs = [ findutils ];
  inheritPath = false;
  text = ''
    find "''${*:-$PWD}" -name .git -type d -prune -print0 |
      xargs --null --max-procs=4 --replace='{}' ${lib.getExe git-fetch-git-dir} '{}'
  '';
  meta.description = "Recursively fetch all git repos";
}
