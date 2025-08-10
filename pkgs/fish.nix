{
  symlinkJoin,
  makeWrapper,
  fish,
  nixbits,
  fish-config ? nixbits.fish-config,
  theme ? null,
}:
let
  fish-config-dir =
    if theme != null then fish-config.overrideAttrs { themeName = theme; } else fish-config;
in
symlinkJoin {
  name = "fish";
  paths = [ fish ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/fish \
      --add-flags "--init-command" \
      --add-flags "'source ${fish-config-dir}/config.fish'"
  '';
  inherit (fish) meta;
}
