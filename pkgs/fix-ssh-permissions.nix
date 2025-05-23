{
  lib,
  writeShellApplication,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "fix-ssh-permissions";
  runtimeInputs = [ coreutils ];
  inheritPath = false;
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./fix-ssh-permissions.bash;

  meta = {
    description = "Fix SSH keys permissions";
    platforms = lib.platforms.all;
  };
}
