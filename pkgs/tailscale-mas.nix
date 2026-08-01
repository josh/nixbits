{
  lib,
  stdenvNoCC,
  formats,
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

  yaml = formats.yaml { };
  defaultsConfig = yaml.generate "tailscale.yml" {
    description = "Tailscale";
    kill = [ "Tailscale" ];
    data = {
      "io.tailscale.ipn.macos" = {
        FileSharingConfiguration = "show";
      };
    };
  };
in
stdenvNoCC.mkDerivation {
  name = "tailscale-mas";

  __structuredAttrs = true;

  buildCommand = ''
    mkdir -p $out/bin $out/share/mas $out/share/nix/hooks/pre-install.d $out/share/defaults.d
    install -m 755 ${wrapper} $out/bin/tailscale
    install -m 755 ${preinstallHook} $out/share/nix/hooks/pre-install.d/tailscale-mas
    echo "Tailscale" >$out/share/mas/1475387142
    cp ${defaultsConfig} $out/share/defaults.d/tailscale.yml
  '';

  meta = {
    description = "Tailscale from the Mac App Store";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "tailscale";
    platforms = lib.platforms.darwin;
  };
}
