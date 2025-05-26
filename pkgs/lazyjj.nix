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
        --set JJ_CONFIG ${nixbits.jujutsu-config} \
        --set XDG_CONFIG_HOME ${nixbits.jujutsu-xdg-config-home}
    '';
  }
)
