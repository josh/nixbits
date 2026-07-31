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
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/zellij \
      --set ZELLIJ_CONFIG_DIR '${configDir}'
  '';

  meta = {
    mainProgram = "zellij";
    inherit (zellij.meta)
      description
      homepage
      license
      platforms
      ;
  };
}
