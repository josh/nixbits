{
  lib,
  writeShellApplication,
  coreutils,
}:
writeShellApplication {
  name = "touch-cachedir-tag";

  runtimeEnv = {
    PATH = lib.strings.makeBinPath [ coreutils ];
  };

  text = ''
    cat ${./cachedir-tag.txt} >CACHEDIR.TAG
  '';

  meta = {
    description = "Create a CACHEDIR.TAG file in the current directory";
    homepage = "http://www.brynosaurus.com/cachedir/";
    mainProgram = "touch-cachdir-tag";
  };
}
