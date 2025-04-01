{
  lib,
  jujutsu,
  lazyjj,
  nixbits,
}:
lazyjj.overrideAttrs (
  _finalAttrs: _previousAttrs: {
    postInstall = ''
      wrapProgram $out/bin/lazyjj \
        --prefix PATH : ${lib.strings.makeBinPath [ jujutsu ]} \
        --set JJ_CONFIG ${nixbits.jujutsu-config}
    '';
  }
)
