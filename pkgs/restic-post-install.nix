{
  lib,
  stdenv,
  writeShellApplication,
  nixbits,
  resticRepository ? "",
}:
let
  inherit (nixbits) tmutil-exclude-volume;
  hasLocalVolumeRepository = stdenv.isDarwin && lib.strings.hasPrefix "/Volumes/" resticRepository;
in
writeShellApplication {
  name = "restic-post-install";
  runtimeInputs = lib.lists.optional hasLocalVolumeRepository tmutil-exclude-volume;
  text = lib.strings.optionalString hasLocalVolumeRepository ''
    tmutil-exclude-volume "${resticRepository}"
  '';
  meta = {
    description = "Run post-install hooks on restic repository";
    platforms = lib.platforms.all;
  };
}
