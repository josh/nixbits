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
    description = "tmux wrapper for iTerm";
    platforms = lib.platforms.darwin;
    mainProgram = "tmux-iterm";
  };
}
