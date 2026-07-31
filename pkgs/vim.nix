{
  stdenvNoCC,
  lndir,
  makeWrapper,
  vim,
}:
stdenvNoCC.mkDerivation {
  pname = "vim";
  inherit (vim) version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    lndir
    makeWrapper
  ];

  buildCommand = ''
    mkdir -p $out
    lndir -silent ${vim} $out

    rm $out/bin/vim
    makeWrapper ${vim}/bin/vim $out/bin/vim \
      --add-flags "-u ${./vimrc}"
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
