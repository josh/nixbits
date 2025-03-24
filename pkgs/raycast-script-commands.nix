{
  lib,
  stdenvNoCC,
  symlinkJoin,
  makeWrapper,
  nixbits,
}:
let
  reset-launchpad = nixbits.raycast-script-command.overrideAttrs {
    name = "reset-launchpad";
    raycast.title = "Reset Launchpad";
    raycast.mode = "silent";
    raycast.icon = "🔄";
    raycast.command = nixbits.reset-launchpad;
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "raycast-script-commands";

  __structuredAttrs = true;

  scriptCommandPaths = [
    reset-launchpad
  ];

  scriptCommandsDir = symlinkJoin {
    name = "raycast-script-commands-dir";
    paths = finalAttrs.scriptCommandPaths;
  };

  nativeBuildInputs = [ makeWrapper ];

  buildCommand = ''
    mkdir -p $out/share/nix/hooks/post-install.d
    makeWrapper \
      ${lib.getExe nixbits.x-lndir} \
      $out/share/nix/hooks/post-install.d/raycast-script-commands \
      --add-flags "$scriptCommandsDir" \
      --add-flags '$HOME/.config/raycast/script-commands'
  '';
  meta = {
    description = "Raycast Script Commands";
    platforms = lib.platforms.darwin;
  };
})
