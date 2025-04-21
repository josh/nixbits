{
  symlinkJoin,
  makeWrapper,
  zellij,
  nixbits,
  zellijTheme ? null,
}:
let
  configDir = nixbits.zellij-config.override { inherit zellijTheme; };
in
symlinkJoin {
  pname = "zellij";
  inherit (zellij) version;

  paths = [
    zellij
  ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/zellij \
      --set ZELLIJ_CONFIG_DIR '${configDir}'
  '';

  meta = {
    inherit (zellij.meta)
      name
      description
      homepage
      license
      platforms
      ;
    mainProgram = "zellij";
  };
}
