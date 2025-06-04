{
  writeShellApplication,
  coreutils,
}:
writeShellApplication {
  name = "touch-cachedir-tag";

  runtimeInputs = [ coreutils ];
  inheritPath = false;

  text = ''
    cat ${./cachedir-tag.txt} >CACHEDIR.TAG
  '';

  meta = {
    description = "Create a CACHEDIR.TAG file in the current directory";
    homepage = "http://www.brynosaurus.com/cachedir/";
    mainProgram = "touch-cachedir-tag";
  };
}
