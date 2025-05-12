{
  stdenvNoCC,
  runtimeShell,
  ghostty,
  nixbits,
}:
stdenvNoCC.mkDerivation {
  __structuredAttrs = true;

  pname = "ghostty-terminfo";
  inherit (ghostty) version;

  postInstallScript = ''
    #!${runtimeShell}
    set -o errexit
    set -o nounset
    export PATH="${nixbits.x-ln-s}/bin"
    x-ln-s ${builtins.placeholder "out"}/share/terminfo/g/ghostty "$HOME/.terminfo/g/ghostty"
    x-ln-s ${builtins.placeholder "out"}/share/terminfo/x/xterm-ghostty "$HOME/.terminfo/x/xterm-ghostty"
  '';

  buildCommand = ''
    mkdir -p $out/share/terminfo/g $out/share/terminfo/x
    cp ${ghostty}/share/terminfo/g/ghostty $out/share/terminfo/g/ghostty
    cp ${ghostty}/share/terminfo/x/xterm-ghostty $out/share/terminfo/x/xterm-ghostty
    [ -f "$out/share/terminfo/g/ghostty" ]
    [ -f "$out/share/terminfo/x/xterm-ghostty" ]

    mkdir -p $out/share/nix/hooks/post-install.d
    echo -n "$postInstallScript" >"$out/share/nix/hooks/post-install.d/ghostty-terminfo"
    chmod +x "$out/share/nix/hooks/post-install.d/ghostty-terminfo"
  '';

  meta = {
    description = "Terminfo for ghostty";
    homepage = "https://ghostty.org/docs/help/terminfo";
    inherit (ghostty.meta) platforms broken;
  };
}
