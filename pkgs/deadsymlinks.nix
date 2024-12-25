{
  lib,
  writeShellApplication,
  findutils,
}:
writeShellApplication {
  name = "deadsymlinks";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      findutils
    ];
  };
  text = ''
    find . -xtype l
  '';
}
