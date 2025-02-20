{
  lib,
  stdenv,
  writeShellApplication,
  gawk,
  gnugrep,
  iproute2,
  unixtools,
}:
let
  darwin-script = writeShellApplication {
    name = "network-gateway";
    runtimeEnv = {
      PATH = lib.strings.makeBinPath [
        gawk
        gnugrep
        unixtools.route
      ];
    };
    text = ''
      route -n get default | grep gateway | awk '{print $2}'
    '';
    meta = {
      description = "Detect default gateway";
      platforms = lib.platforms.darwin;
    };
  };

  linux-script = writeShellApplication {
    name = "network-gateway";
    runtimeEnv = {
      PATH = lib.strings.makeBinPath [
        gawk
        gnugrep
        iproute2
      ];
    };
    text = ''
      ip route | grep default | awk '{print $3}'
    '';
    meta = {
      description = "Detect default gateway";
      platforms = lib.platforms.linux;
    };
  };
in
if stdenv.isDarwin then darwin-script else linux-script
