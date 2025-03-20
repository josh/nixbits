{
  stdenvNoCC,
  makeWrapper,
  lndir,
  tmux,
  nixbits,
  theme ? null,
}:
let
  tmuxConf = nixbits.tmux-conf.override { inherit theme; };
in
stdenvNoCC.mkDerivation (_finalAttrs: {
  pname = if theme != null then "${tmux.pname}-${theme}" else tmux.pname;
  inherit (tmux) version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
    lndir
  ];

  makeWrapperArgs = [
    "--add-flags"
    "-f ${tmuxConf}"
  ];

  buildCommand = ''
    mkdir -p $out
    lndir -silent ${tmux} $out

    rm $out/bin/tmux
    makeWrapper ${tmux}/bin/tmux $out/bin/tmux "''${makeWrapperArgs[@]}"
  '';

  meta = {
    inherit (tmux.meta) description license platforms;
    mainProgram = "tmux";
  };
})
