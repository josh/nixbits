{
  lib,
  writeShellApplication,
  darwin,
  coreutils,
  diffutils,
}:
writeShellApplication {
  name = "sudo-enable-pam-tid";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      diffutils
      darwin.sudo
    ];
  };
  text = ''
    DRY_RUN=0
    while [[ $# -gt 0 ]]; do
      case $1 in
        --dry-run)
          DRY_RUN=1
          shift
          ;;
        *)
          echo "unknown option: $1" >&2
          exit 1
          ;;
      esac
    done

    if [ -f /etc/pam.d/sudo_local ] && diff /etc/pam.d/sudo_local ${./sudo_local}; then
      echo "pam_tid already enabled" >&2
      exit 0
    fi

    x() {
      echo + "$@" >&2
      if [ "$DRY_RUN" -eq 0 ]; then
        "$@"
      fi
    }

    echo "enabling pam_tid" >&2
    x sudo ${coreutils}/bin/install -m 444 ${./sudo_local} /etc/pam.d/sudo_local
  '';
  meta = {
    description = "Enable sudo authentication with Touch ID";
    platforms = lib.platforms.darwin;
  };
}
