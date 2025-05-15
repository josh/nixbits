{
  lib,
  python3,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (_finalAttrs: {
  __structuredAttrs = true;

  name = "zsh-history-merge";

  buildCommand = ''
    mkdir -p $out/bin
    (
      echo "#!${python3.interpreter}"
      cat "${./zsh-history-merge.py}"
    ) >$out/bin/zsh-history-merge
    chmod +x $out/bin/zsh-history-merge
  '';

  meta = {
    mainProgram = "zsh-history-merge";
    description = "Merge multiple zsh history files";
    platforms = lib.platforms.all;
  };
})
