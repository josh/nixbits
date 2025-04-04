{
  lib,
  writeShellApplication,
  coreutils,
  darwin,
  nixbits,
}:
writeShellApplication {
  name = "launchd-exec-install";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      darwin.sudo
    ];
    VERSION = nixbits.launchd-exec.version;
  };
  text = ''
    # shellcheck source=/dev/null
    source "${nixbits.xtrace}/share/bash/xtrace.bash"

    if [ ! -d /usr/local/bin ]; then
      x sudo ${coreutils}/bin/mkdir -p /usr/local/bin
    fi

    if [ ! -x /usr/local/bin/launchd-exec ] || [ "$(/usr/local/bin/launchd-exec --version)" != "$VERSION" ]; then
      x sudo ${coreutils}/bin/install -m 755 ${nixbits.launchd-exec}/bin/launchd-exec /usr/local/bin/launchd-exec
    fi
  '';
  meta = {
    description = "Install launchd-exec wrapper";
    platforms = lib.platforms.darwin;
  };
}
