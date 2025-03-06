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

if [ -f /etc/pam.d/sudo_local ] && diff /etc/pam.d/sudo_local "$SUDO_LOCAL_TEMPLATE"; then
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
install_path=$(which install)
x sudo "$install_path" -m 444 "$SUDO_LOCAL_TEMPLATE" /etc/pam.d/sudo_local
