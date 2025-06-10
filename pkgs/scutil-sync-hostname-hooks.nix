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

  binPath = lib.getExe nixbits.scutil-sync-hostname;

  buildCommand = ''
    mkdir -p $out/share/nix/hooks/pre-install.d $out/share/nix/hooks/post-install.d
    makeWrapper $binPath $out/share/nix/hooks/pre-install.d/hostname --add-flags "--dry-run"
    makeWrapper $binPath $out/share/nix/hooks/post-install.d/hostname
  '';

  meta = {
    description = "Automatically sync hostname to the local hostname";
    platforms = lib.platforms.darwin;
  };
}
