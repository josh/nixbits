{
  lib,
  writeShellApplication,
  findutils,
  git,
}:
writeShellApplication {
  name = "git-fetch-dir";
  runtimeInputs = [ findutils ];
  inheritPath = false;
  text = ''
    find "''${@:-$PWD}" -name .git -type d -prune -print0 |
      xargs --null --max-procs=4 --replace='{}' --verbose ${lib.getExe git} --git-dir='{}' fetch --all --quiet
  '';
  meta = {
    description = "Recursively fetch all git repos";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
