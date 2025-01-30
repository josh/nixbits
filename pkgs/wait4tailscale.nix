{
  lib,
  writeShellApplication,
  coreutils,
  jq,
  tailscale,
}:
writeShellApplication {
  name = "wait4tailscale";
  runtimeEnv = {
    PATH = lib.makeBinPath [
      coreutils
      jq
      tailscale
    ];
  };
  text = builtins.readFile ./wait4tailscale.bash;

  meta = {
    description = "Wait for Tailscale to be online";
    platforms = lib.platforms.all;
  };
}
