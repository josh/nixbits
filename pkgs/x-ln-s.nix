{
  lib,
  writeShellApplication,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "x-ln-s";
  runtimeEnv = {
    "PATH" = lib.strings.makeBinPath [
      coreutils
    ];
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./x-ln-s.bash;
  meta = {
    description = "Conditionally update symlink";
    platforms = lib.platforms.all;
  };
}
