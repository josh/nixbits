{
  lib,
  stdenvNoCC,
  writeShellApplication,
  coreutils,
  gawk,
  gnugrep,
  unixtools,
}:
let
  script = writeShellApplication {
    name = "internal-ip";
    runtimeInputs = [
      coreutils
      gawk
      gnugrep
      unixtools.ifconfig
    ];
    inheritPath = false;
    text = builtins.readFile ./internal-ip.bash;
  };
in
stdenvNoCC.mkDerivation {
  name = "internal-ip";

  __structuredAttrs = true;

  buildCommand = ''
    mkdir -p $out/bin
    install -m 755 ${lib.getExe script} $out/bin/internal-ip
    install -m 755 ${lib.getExe script} $out/bin/lan-ip
  '';

  meta = {
    description = "Get the internal IP address";
    license = lib.licenses.mit;
    mainProgram = "internal-ip";
    platforms = lib.platforms.all;
  };
}
