{
  lib,
  writeShellApplication,
  coreutils,
}:
writeShellApplication {
  name = "x-ln-s";
  runtimeEnv = {
    "PATH" = lib.strings.makeBinPath [
      coreutils
    ];
  };
  text = builtins.readFile ./x-ln-s.bash;
  meta = {
    description = "Conditionally update symlink";
    platforms = lib.platforms.all;
  };
}
