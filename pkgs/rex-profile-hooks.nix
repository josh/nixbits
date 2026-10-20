{
  lib,
  stdenvNoCC,
  makeWrapper,
  nixbits,
}:
stdenvNoCC.mkDerivation {
  name = "rex-profile-hooks";

  __structuredAttrs = true;

  nativeBuildInputs = [ makeWrapper ];

  binPath = lib.getExe nixbits.rex-setup;

  buildCommand = ''
    mkdir -p $out/share/nix/hooks/post-install.d
    makeWrapper $binPath $out/share/nix/hooks/post-install.d/rex
  '';

  meta = {
    description = "Automatically set up Rex terminfo, ssh guard and agent skills";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
