{
  lib,
  stdenv,
  writeShellApplication,
  nixbits,
  resticRepository ? null,
  resticPasswordCommand ? null,
}:
let
  inherit (nixbits) tmutil-exclude-volume;
  isPresent = s: s != null && s != "";

  hasLocalRepository = (isPresent resticRepository) && !lib.strings.hasPrefix "/" resticRepository;
  hasLocalVolumeRepository =
    stdenv.isDarwin
    && (isPresent resticRepository)
    && lib.strings.hasPrefix "/Volumes/" resticRepository;
in
writeShellApplication {
  name = "restic-pre-install";
  runtimeInputs = lib.lists.optional hasLocalVolumeRepository tmutil-exclude-volume;
  text =
    (lib.strings.optionalString hasLocalRepository ''
      if [ ! -f "${resticRepository}/config" ]; then
        echo "error: ${resticRepository} restic repository not initialized" >&2
        exit 1
      fi
    '')
    + (lib.strings.optionalString hasLocalVolumeRepository ''
      tmutil-exclude-volume --dry-run "${resticRepository}"
    '')
    + (lib.strings.optionalString (isPresent resticPasswordCommand) ''
      ${nixbits.x-quiet}/bin/x-quiet -- ${resticPasswordCommand}
    '');
  meta = {
    description = "Run pre-install hooks on restic repository";
    platforms = lib.platforms.all;
  };
}
