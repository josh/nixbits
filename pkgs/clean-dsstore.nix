{
  lib,
  writeShellApplication,
  coreutils,
  findutils,
}:
writeShellApplication {
  name = "clean-dsstore";
  
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      findutils
    ];
  };

  text = ''
    find . -type f -name ".DS_Store" -print -delete
  '';

  meta = {
    description = "Clean .DS_Store files recursively";
    platforms = lib.platforms.darwin;
  };
}
