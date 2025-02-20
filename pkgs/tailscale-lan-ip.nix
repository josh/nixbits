{
  lib,
  writeShellApplication,
  gawk,
  gnugrep,
  tailscale,
  unixtools,
}:
writeShellApplication {
  name = "tailscale-lan-ip";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      gawk
      gnugrep
      tailscale
      unixtools.route
    ];
  };
  text = builtins.readFile ./tailscale-lan-ip.bash;
  meta = {
    description = "Detect Tailscale node LAN IP";
    platforms = lib.platforms.all;
  };
}
