# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

usage() {
  echo "usage: sc-auth-ssh-keygen [--dry-run] [LABEL]" >&2
}

dry_run=false
label=""

for arg in "$@"; do
  case "$arg" in
  "--dry-run")
    dry_run=true
    ;;
  -*)
    usage
    exit 1
    ;;
  *)
    if [ -n "$label" ]; then
      usage
      exit 1
    fi
    label="$arg"
    ;;
  esac
done

list_fingerprints() {
  sc_auth list-ctk-identities -t ssh | awk '$1 == "p-256-ne" { print $2 }'
}

has_fingerprint() {
  ssh-keygen -lf "$1" | awk '{ print $2 }' | grep -qxF -f <(echo "$fingerprints")
}

fingerprints=$(list_fingerprints)

if [ -z "$fingerprints" ]; then
  if [ -z "$label" ]; then
    label="$USER@$(scutil --get LocalHostName).local"
    echo "warn: using '$label' as key label" >&2
  fi
  x-dry-run $dry_run -- sc_auth create-ctk-identity -l "$label" -k p-256-ne -t none
  if [ "$dry_run" = true ]; then
    exit 0
  fi
  fingerprints=$(list_fingerprints)
fi

stub="$HOME/.ssh/id_ecdsa_sk_rk"

if [ -f "$stub" ] && [ -f "$stub.pub" ] && has_fingerprint "$stub.pub"; then
  cat "$stub.pub"
  exit 0
fi

if [ -e "$stub" ] || [ -e "$stub.pub" ]; then
  echo "error: $stub does not match a Secure Enclave key" >&2
  exit 1
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir" || exit 1
ssh-keygen -K -N "" -q

for pub in "$tmpdir"/*.pub; do
  if has_fingerprint "$pub"; then
    if [ ! -d "$HOME/.ssh" ]; then
      x-dry-run $dry_run -- install -d -m 700 "$HOME/.ssh"
    fi
    x-dry-run $dry_run -- install -m 600 "${pub%.pub}" "$stub"
    x-dry-run $dry_run -- install -m 644 "$pub" "$stub.pub"
    cat "$pub"
    exit 0
  fi
done

echo "error: no resident key matches a Secure Enclave key" >&2
exit 1
