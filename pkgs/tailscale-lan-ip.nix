{
  lib,
  writeShellApplication,
  tailscale,
}:
writeShellApplication {
  name = "tailscale-lan-ip";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      tailscale
    ];
  };
  text = builtins.readFile ./tailscale-lan-ip.bash;
  meta = {
    description = "Detect Tailscale node LAN IP";
    platforms = lib.platforms.all;
  };
}
