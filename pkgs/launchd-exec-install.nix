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
  inherit (nur.repos.josh) tccpolicy;
  inherit (nixbits) launchctl-spawn;

  tcc-system-policy = writers.writeJSON "launch-exec-tccpolicy.json" {
    "SystemPolicyAllFiles" = true;
  };
  # tcc-user-policy = writers.writeJSON "launch-exec-tccpolicy.json" {
  #   "AppleEvents" = [
  #     "com.apple.systemevents"
  #   ];
  # };
in
writeShellApplication {
  name = "launchd-exec-install";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      darwin.sudo
      launchctl-spawn
      nixbits.darwin.open
      tccpolicy
    ];
    INSTALL_PATH = "/usr/local/bin/launchd-exec";
    INSTALL_DIR = "/usr/local/bin";
    SYSTEM_POLICY_FILE = tcc-system-policy;
    # USER_POLICY_FILE = tcc-user-policy;
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

    if ! x-silent tccpolicy check --client "$INSTALL_PATH" --policy "$SYSTEM_POLICY_FILE"; then
      open "$INSTALL_DIR"
      open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
      exit 1
    fi

    # if ! x-silent tccpolicy check --client "$INSTALL_PATH" --policy "$USER_POLICY_FILE"; then
    #   x launchctl-spawn -- "$INSTALL_PATH" ${tccpolicy}/bin/tccpolicy request --policy "$USER_POLICY_FILE"
    #   exit 1
    # fi
  '';
  meta = {
    description = "Install launchd-exec wrapper";
    platforms = lib.platforms.darwin;
  };
}
