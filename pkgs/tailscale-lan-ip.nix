{
  lib,
  writeShellApplication,
  gnugrep,
  tailscale,
  nixbits,
}:
writeShellApplication {
  name = "tailscale-lan-ip";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      gnugrep
      tailscale
      nixbits.network-gateway
    ];
  };
  text = builtins.readFile ./tailscale-lan-ip.bash;
  meta = {
    description = "Detect Tailscale node LAN IP";
    platforms = lib.platforms.all;
  };
}
