{
  lib,
  stdenvNoCC,
  writeShellScript,
}:
let
  wrapper = writeShellScript "tailscale" ''
    exec "/Applications/Tailscale.app/Contents/MacOS/Tailscale" "$@"
  '';
  preinstallHook = writeShellScript "tailscale-mas-preinstall-hook" ''
    if [ ! -d "/Applications/Tailscale.app" ]; then
      echo "warn: Tailscale is not installed" >&2
    fi
  '';
in
stdenvNoCC.mkDerivation {
  name = "tailscale-mas";

  buildCommand = ''
    mkdir -p $out/bin $out/share/mas $out/share/nix/hooks/pre-install.d
    install -m 755 ${wrapper} $out/bin/tailscale
    install -m 755 ${preinstallHook} $out/share/nix/hooks/pre-install.d/tailscale-mas
    echo "Tailscale" >$out/share/mas/1475387142
  '';

  meta = {
    description = "Tailscale from the Mac App Store";
    mainProgram = "tailscale";
    platforms = lib.platforms.darwin;
  };
}
