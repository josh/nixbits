{
  stdenvNoCC,
  makeWrapper,
  lndir,
  vim,
}:
stdenvNoCC.mkDerivation {
  name = "vim";

  __structuredAttrs = true;

  buildInputs = [ makeWrapper ];

  buildCommand = ''
    mkdir -p $out
    ${lndir}/bin/lndir -silent ${vim} $out

    rm $out/bin/vim
    makeWrapper ${vim}/bin/vim $out/bin/vim \
      --append-flags "-u ${./vimrc}"
  '';
  meta = {
    inherit (vim.meta)
      description
      homepage
      license
      mainProgram
      platforms
      ;
  };
}
