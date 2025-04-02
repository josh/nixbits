{
  lib,
  writeShellApplication,
  coreutils,
  findutils,
  nixbits,
}:
writeShellApplication {
  name = "launchctl-user-activate";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      findutils
      nixbits.darwin.launchctl
    ];
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./launchctl-user-activate.bash;
  meta = {
    description = "Install LaunchAgents plists for current user";
    mainProgram = "launchctl-user-activate";
    platforms = lib.platforms.darwin;
  };
}
