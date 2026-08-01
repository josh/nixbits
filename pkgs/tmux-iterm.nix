{
  lib,
  stdenvNoCC,
  makeWrapper,
  tmux,
}:
stdenvNoCC.mkDerivation {
  pname = "tmux-iterm";
  inherit (tmux) version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  makeWrapperArgs = [
    "--add-flags"
    "-CC new-session -A -s main"
  ];

  buildCommand = ''
    mkdir -p $out
    makeWrapper ${tmux}/bin/tmux $out/bin/tmux-iterm \
      "''${makeWrapperArgs[@]}"
  '';

  meta = {
    description = "Wrapper starting tmux in iTerm2 control mode";
    inherit (tmux.meta) license;
    mainProgram = "tmux-iterm";
    platforms = lib.platforms.darwin;
  };
}
