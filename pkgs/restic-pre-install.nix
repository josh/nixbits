{
  lib,
  stdenv,
  writeShellApplication,
  nixbits,
  resticRepository ? "",
  resticPasswordCommand ? "",
}:
let
  inherit (nixbits) tmutil-exclude-volume;

  hasLocalRepository = lib.strings.hasPrefix "/" resticRepository;
  hasLocalVolumeRepository = stdenv.isDarwin && lib.strings.hasPrefix "/Volumes/" resticRepository;
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
    + (lib.strings.optionalString (resticPasswordCommand != "") ''
      if ! result=$(${resticPasswordCommand} 2>&1); then
        echo "+ ${resticPasswordCommand}" >&2
        echo "$result" >&2
        exit 1
      fi
    '');
  meta = {
    description = "Run pre-install hooks on restic repository";
    platforms = lib.platforms.all;
  };
}
