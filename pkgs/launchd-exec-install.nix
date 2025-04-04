{
  lib,
  writers,
  writeShellApplication,
  coreutils,
  darwin,
  nur,
  nixbits,
}:
let
  tccpolicy = {
    "SystemPolicyAllFiles" = true;
    "AppleEvents" = [
      "com.apple.systemevents"
    ];
  };
  tccpolicy-file = writers.writeJSON "launch-exec-tccpolicy.json" tccpolicy;
in
writeShellApplication {
  name = "launchd-exec-install";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      darwin.sudo
      nixbits.darwin.open
      nur.repos.josh.tccpolicy
    ];
    INSTALL_PATH = "/usr/local/bin/launchd-exec";
    INSTALL_DIR = "/usr/local/bin";
    POLICY_FILE = tccpolicy-file;
    VERSION = nixbits.launchd-exec.version;
  };
  text = ''
    # shellcheck source=/dev/null
    source "${nixbits.xtrace}/share/bash/xtrace.bash"

    if [ ! -d "$INSTALL_DIR" ]; then
      x sudo ${coreutils}/bin/mkdir -p "$INSTALL_DIR"
    fi

    if [ ! -x "$INSTALL_PATH" ] || [ "$("$INSTALL_PATH" --version)" != "$VERSION" ]; then
      x sudo ${coreutils}/bin/install -m 755 ${nixbits.launchd-exec}/bin/launchd-exec "$INSTALL_PATH"
    fi

    if ! x-silent tccpolicy check --client "$INSTALL_PATH" --policy "$POLICY_FILE"; then
      open "$INSTALL_DIR"
      open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
      exit 1
    fi
  '';
  meta = {
    description = "Install launchd-exec wrapper";
    platforms = lib.platforms.darwin;
  };
}
