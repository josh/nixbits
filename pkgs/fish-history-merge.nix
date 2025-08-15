{
  lib,
  python3,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (_finalAttrs: {
  __structuredAttrs = true;

  name = "fish-history-merge";

  buildCommand = ''
    mkdir -p $out/bin
    (
      echo "#!${python3.interpreter}"
      cat "${./fish-history-merge.py}"
    ) >$out/bin/fish-history-merge
    chmod +x $out/bin/fish-history-merge
  '';

  meta = {
    mainProgram = "fish-history-merge";
    description = "Merge multiple fish history files";
    platforms = lib.platforms.all;
  };
})
