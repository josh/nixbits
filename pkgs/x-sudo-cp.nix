{
  lib,
  writeShellApplication,
  coreutils,
  diffutils,
  nixbits,
  overrideSudo ? nixbits.sudo,
}:
writeShellApplication {
  name = "x-sudo-cp";
  runtimeEnv = {
    "PATH" = lib.strings.makeBinPath [
      coreutils
      diffutils
      overrideSudo
    ];
    COREUTILS_PATH = coreutils;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./x-sudo-cp.bash;
  meta = {
    description = "Conditionally copy files with sudo";
    platforms = lib.platforms.all;
  };
}
