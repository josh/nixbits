{
  lib,
  writeShellApplication,
  coreutils,
}:
writeShellApplication {
  name = "x-ln";
  runtimeEnv = {
    "PATH" = lib.strings.makeBinPath [
      coreutils
    ];
  };
  text = builtins.readFile ./x-ln.bash;
  meta = {
    description = "Conditionally update symlink";
    platforms = lib.platforms.all;
  };
}
