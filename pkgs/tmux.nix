{
  stdenvNoCC,
  makeWrapper,
  lndir,
  bash,
  tmux,
  nixbits,
  interactiveShell ? "${bash}/bin/bash",
  theme ? null,
}:
let
  tmuxConf = nixbits.tmux-conf.override { inherit interactiveShell theme; };
in
stdenvNoCC.mkDerivation {
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
}
