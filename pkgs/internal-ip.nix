{
  lib,
  stdenvNoCC,
  writeShellApplication,
  coreutils,
  gawk,
  gnugrep,
  nettools,
}:
let
  script = writeShellApplication {
    name = "internal-ip";
    runtimeInputs = [
      coreutils
      gawk
      gnugrep
      nettools
    ];
    inheritPath = false;
    text = builtins.readFile ./internal-ip.bash;
  };
in
stdenvNoCC.mkDerivation {
  __structuredAttrs = true;

  name = "internal-ip";

  buildCommand = ''
    mkdir -p $out/bin
    install -m 755 ${lib.getExe script} $out/bin/internal-ip
    install -m 755 ${lib.getExe script} $out/bin/lan-ip
  '';

  meta = {
    description = "Get the internal IP address";
    mainProgram = "internal-ip";
    platforms = lib.platforms.all;
  };
}
