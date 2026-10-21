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

list_identities() {
  sc_auth list-ctk-identities -t ssh | awk '$1 == "p-256-ne" { print $2, $4 }'
}

key_label() {
  ssh-keygen -lf "$1" | awk 'NR == FNR { labels[$1] = $2; next } { print labels[$2] }' <(echo "$identities") -
}

identities=$(list_identities)

if [ -z "$identities" ]; then
  if [ -z "$label" ]; then
    label="$USER@$(scutil --get LocalHostName).local"
    echo "warn: using '$label' as key label" >&2
  fi
  x-dry-run $dry_run -- sc_auth create-ctk-identity -l "$label" -k p-256-ne -t none
  if [ "$dry_run" = true ]; then
    exit 0
  fi
  identities=$(list_identities)
fi

stub="$HOME/.ssh/id_ecdsa_sk_rk"

if [ -f "$stub" ] && [ -f "$stub.pub" ]; then
  stub_label=$(key_label "$stub.pub")
  if [ -n "$stub_label" ]; then
    if [ "$(awk '{ print $3 }' "$stub.pub")" != "$stub_label" ]; then
      x-dry-run $dry_run -- ssh-keygen -c -C "$stub_label" -f "$stub" >&2
    fi
    cat "$stub.pub"
    exit 0
  fi
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
  pub_label=$(key_label "$pub")
  if [ -n "$pub_label" ]; then
    ssh-keygen -c -C "$pub_label" -f "${pub%.pub}" >&2
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
