{
  lib,
  stdenvNoCC,
  writeShellScript,
  nixbits,
}:
let
  reset-launchpad = writeShellScript "reset-launchpad.sh" ''
    # Required parameters:
    # @raycast.schemaVersion 1
    # @raycast.title Reset Launchpad
    # @raycast.mode silent

    # Optional parameters:
    # @raycast.icon 🔄

    exec "${lib.getExe nixbits.reset-launchpad}"
  '';

  raycast-script-commands-post-install-hook = writeShellScript "post-install.sh" ''
    set -o errexit
    set -o nounset
    set -o pipefail
    export PATH="${nixbits.x-ln-s}/bin:$PATH"

    mkdir -p $HOME/.config/raycast/script-commands

    rm -f $HOME/.config/raycast/script-commands/*.sh

    x-ln-s ${reset-launchpad} $HOME/.config/raycast/script-commands/reset-launchpad.sh
  '';
in
stdenvNoCC.mkDerivation {
  name = "raycast-script-commands";
  buildCommand = ''
    mkdir -p $out/share/nix/hooks/post-install.d
    install -m 755 ${raycast-script-commands-post-install-hook} $out/share/nix/hooks/post-install.d/raycast-script-commands
  '';
  meta = {
    description = "Raycast Script Commands";
    platforms = lib.platforms.darwin;
  };
}
