{
  lib,
  writeShellApplication,
  coreutils,
}:
writeShellApplication {
  name = "fix-ssh-permissions";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
    ];
  };
  text = builtins.readFile ./fix-ssh-permissions.bash;

  meta = {
    description = "Fix SSH keys permissions";
    platforms = lib.platforms.all;
  };
}
