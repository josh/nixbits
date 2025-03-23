{
  symlinkJoin,
  makeWrapper,
  fish,
  nixbits,
  theme ? null,
}:
let
  fish-config-dir = nixbits.fish-config.override { inherit theme; };
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
