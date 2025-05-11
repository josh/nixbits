{
  writeShellApplication,
  findutils,
}:
writeShellApplication {
  name = "deadsymlinks";
  runtimeInputs = [ findutils ];
  inheritPath = false;
  text = ''
    find . -xtype l
  '';

  meta.description = "Find dead symlinks";
}
