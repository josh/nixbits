{
  lib,
  symlinkJoin,
  makeWrapper,
  wget,
}:
symlinkJoin {
  inherit (wget) name;
  paths = [ wget ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    rm $out/bin/wget
    makeWrapper ${lib.getExe wget} $out/bin/wget \
      --add-flags '--hsts-file=''${XDG_DATA_HOME:-$HOME/.local/share}/wget-hsts'
  '';
  meta = {
    inherit (wget.meta)
      description
      homepage
      license
      mainProgram
      platforms
      ;
  };
}
