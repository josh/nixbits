{
  lib,
  writeShellApplication,
  coreutils,
  gnugrep,
  nixbits,
}:
writeShellApplication {
  name = "launchctl-spawn";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      gnugrep
      nixbits.darwin.launchctl
    ];
  };
  text = builtins.readFile ./launchctl-spawn.bash;
  meta = {
    description = "Spawn a process using launchctl";
    platforms = lib.platforms.darwin;
  };
}
