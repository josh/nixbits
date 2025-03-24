{
  lib,
  stdenvNoCC,
  symlinkJoin,
  makeWrapper,
  lndir,
  nixbits,
}:
let
  bbedit-scratchpad = nixbits.raycast-script-command.overrideAttrs {
    name = "bbedit-scratchpad";
    raycast.title = "BBEdit Scratchpad";
    raycast.mode = "silent";
    raycast.icon = "📝";
    raycast.command = nixbits.bbedit-scratchpad;
  };

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
    bbedit-scratchpad
    reset-launchpad
  ];

  scriptCommandsDir = symlinkJoin {
    name = "raycast-script-commands-dir";
    paths = finalAttrs.scriptCommandPaths;
  };

  nativeBuildInputs = [
    makeWrapper
    lndir
  ];

  buildCommand = ''
    mkdir -p $out/share/raycast
    lndir "$scriptCommandsDir" $out/share/raycast

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
