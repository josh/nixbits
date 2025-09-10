{
  lib,
  stdenvNoCC,
  makeWrapper,
  nixbits,
}:
stdenvNoCC.mkDerivation {
  __structuredAttrs = true;

  name = "scutil-sync-hostname-hooks";

  nativeBuildInputs = [ makeWrapper ];

  computerName = "";
  binPath = lib.getExe nixbits.scutil-set-hostname;

  buildCommand = ''
    mkdir -p $out/share/nix/hooks/pre-install.d $out/share/nix/hooks/post-install.d
    makeWrapper $binPath $out/share/nix/hooks/pre-install.d/scutil --add-flags "--dry-run" --add-flags "$computerName"
    makeWrapper $binPath $out/share/nix/hooks/post-install.d/scutil --add-flags "$computerName"
  '';

  meta = {
    description = "Automatically update macOS computer name";
    platforms = lib.platforms.darwin;
  };
}
