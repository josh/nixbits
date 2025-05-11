{
  lib,
  writeShellApplication,
  tailscale,
}:
writeShellApplication {
  name = "tailscale-lan-ip";
  runtimeInputs = [ tailscale ];
  inheritPath = false;
  text = builtins.readFile ./tailscale-lan-ip.bash;
  meta = {
    description = "Detect Tailscale node LAN IP";
    platforms = lib.platforms.all;
  };
}
