{
  lib,
  writeShellApplication,
  coreutils,
  gnugrep,
  nixbits,
}:
writeShellApplication {
  name = "launchctl-spawn";
  runtimeInputs = [
    coreutils
    gnugrep
    nixbits.darwin.launchctl
  ];
  inheritPath = false;
  text = builtins.readFile ./launchctl-spawn.bash;
  meta = {
    description = "Spawn a process using launchctl";
    platforms = lib.platforms.darwin;
  };
}
