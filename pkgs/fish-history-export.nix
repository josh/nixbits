{
  lib,
  stdenvNoCC,
  python3,
}:
stdenvNoCC.mkDerivation (_finalAttrs: {
  __structuredAttrs = true;

  name = "fish-history-export";

  buildCommand = ''
    mkdir -p $out/bin
    (
      echo "#!${python3.interpreter}"
      cat "${./fish-history-export.py}"
    ) >$out/bin/fish-history-export
    chmod +x $out/bin/fish-history-export
  '';

  meta = {
    mainProgram = "fish-history-export";
    description = "Export fish history to zsh history";
    platforms = lib.platforms.all;
  };
})
