{
  lib,
  stdenvNoCC,
  makeWrapper,
  mas,
  nixbits,
}:
stdenvNoCC.mkDerivation {
  __structuredAttrs = true;

  name = "mas-profile-hooks";

  nativeBuildInputs = [ makeWrapper ];

  masActivateBin = lib.getExe (nixbits.mas-activate.override { inherit mas; });

  buildCommand = ''
    mkdir -p $out/share/nix/hooks/pre-install.d $out/share/nix/hooks/post-install.d

    makeWrapper $masActivateBin $out/share/nix/hooks/pre-install.d/mas \
      --add-flags "--dry-run" \
      --add-flags '$NIX_NEW_PROFILE/share/mas'

    makeWrapper $masActivateBin $out/share/nix/hooks/post-install.d/mas \
      --add-flags '$NIX_NEW_PROFILE/share/mas'
  '';

  meta = {
    description = "Automatically install Mac App Store Apps in the current Nix profile";
    platforms = lib.platforms.darwin;
  };
}
