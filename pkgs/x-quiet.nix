# TODO: Deprecate this
{
  lib,
  writeShellApplication,
  nixbits,
}:
writeShellApplication {
  name = "x-quiet";
  text = ''
    # shellcheck disable=SC1091
    source ${nixbits.xtrace}/share/bash/xtrace.bash
    [ "$1" == "--" ] && shift
    x-silent "$@"
  '';
  meta = {
    description = "Runs command, if succesful is silent, else log to stderr";
    platforms = lib.platforms.all;
  };
}
