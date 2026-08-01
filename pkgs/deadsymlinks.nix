{
  lib,
  writeShellApplication,
  findutils,
}:
writeShellApplication {
  name = "deadsymlinks";
  runtimeInputs = [ findutils ];
  inheritPath = false;
  text = ''
    find "''${@:-.}" -xtype l
  '';

  meta = {
    description = "Find dead symlinks";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
