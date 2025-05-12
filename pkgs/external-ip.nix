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
      curl
      coreutils
      gnugrep
    ];
    inheritPath = false;
    text = ''
      curl --silent https://cloudflare.com/cdn-cgi/trace | grep ip= | cut -d= -f2
    '';
  };
in
stdenvNoCC.mkDerivation {
  __structuredAttrs = true;

  name = "external-ip";

  buildCommand = ''
    mkdir -p $out/bin
    install -m 755 ${lib.getExe script} $out/bin/external-ip
    install -m 755 ${lib.getExe script} $out/bin/whats-my-ip
    install -m 755 ${lib.getExe script} $out/bin/whatsmyip
  '';

  meta = {
    description = "Get the external IP address";
    mainProgram = "external-ip";
    platforms = lib.platforms.all;
  };
}
