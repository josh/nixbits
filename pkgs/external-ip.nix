{
  lib,
  stdenvNoCC,
  writeShellApplication,
  coreutils,
  curl,
  gnugrep,
}:
let
  script = writeShellApplication {
    name = "external-ip";
    runtimeInputs = [
      coreutils
      curl
      gnugrep
    ];
    inheritPath = false;
    text = ''
      curl --silent https://cloudflare.com/cdn-cgi/trace | grep ip= | cut -d= -f2
    '';
  };
in
stdenvNoCC.mkDerivation {
  name = "external-ip";

  __structuredAttrs = true;

  buildCommand = ''
    mkdir -p $out/bin
    install -m 755 ${lib.getExe script} $out/bin/external-ip
    install -m 755 ${lib.getExe script} $out/bin/whats-my-ip
    install -m 755 ${lib.getExe script} $out/bin/whatsmyip
  '';

  meta = {
    description = "Get the external IP address";
    license = lib.licenses.mit;
    mainProgram = "external-ip";
    platforms = lib.platforms.all;
  };
}
