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
    runtimeInputs = [
      gawk
      gnugrep
      unixtools.route
    ];
    inheritPath = false;
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
    runtimeInputs = [
      gawk
      gnugrep
      iproute2
    ];
    inheritPath = false;
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
