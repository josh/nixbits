{
  lib,
  stdenvNoCC,
  runtimeShell,
  nixbits,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "ghostty-config";

  __structuredAttrs = true;

  config = {
    "auto-update" = "off";
    "font-family" = "Berkeley Mono Regular";
    "font-family-bold" = "Berkeley Mono Bold";
    "font-family-italic" = "Berkeley Mono Oblique";
    "font-family-bold-italic" = "Berkeley Mono Bold Oblique";
    "font-thicken" = "true";
    "font-size" = 20;
    "theme" = "TokyoNight Storm";
    "background-opacity" = "0.95";
    "background-blur-radius" = 20;
    "window-height" = 40;
    "window-width" = 100;
  };

  text = builtins.concatStringsSep "" (
    lib.attrsets.mapAttrsToList (
      name: value: "${name} = ${builtins.toString value}\n"
    ) finalAttrs.config
  );

  postInstallText = ''
    #!${runtimeShell}
    set -o errexit
    set -o nounset

    target="$HOME/.config/ghostty/config"
    if [ -n "''${XDG_CONFIG_HOME:-}" ]; then
      target="$XDG_CONFIG_HOME/ghostty/config"
    fi
    if [ -d "$HOME/Library/Application Support/com.mitchellh.ghostty" ]; then
      target="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
    fi

    exec ${lib.getExe nixbits.x-ln-s} "${builtins.placeholder "out"}/share/ghostty/config" "$target"
  '';

  buildCommand = ''
    mkdir -p $out/share/ghostty
    mkdir -p $out/share/nix/hooks/post-install.d

    echo -n "$text" >$out/share/ghostty/config

    if ${lib.getExe nixbits.ghostty-validate-config} $out/share/ghostty/config; then
      echo "$out/share/ghostty/config: OK"
    elif [ $? -eq 127 ]; then
      echo "warn: ghostty-validate-config not supported"
    else
      exit $?
    fi

    echo -n "$postInstallText" >$out/share/nix/hooks/post-install.d/ghostty-config
    chmod +x $out/share/nix/hooks/post-install.d/ghostty-config
    $SHELL -n $out/share/nix/hooks/post-install.d/ghostty-config
  '';

  meta = {
    description = "Ghostty config";
  };
})
