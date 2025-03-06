usage() {
  echo "usage: shortcuts-check --id ID [--name NAME]" >&2
}

id=""
expected_name=""

while [[ $# -gt 0 ]]; do
  case "$1" in
  --help)
    usage
    exit 0
    ;;
  --name)
    expected_name="$2"
    shift 2
    ;;
  --id)
    id="$2"
    shift 2
    ;;
  *)
    echo "error: unknown option: $1" >&2
    usage
    exit 1
    ;;
  esac
done

if [ -z "$id" ]; then
  usage
  exit 1
fi

shortcut_match=$(shortcuts list --show-identifiers | grep "(${id})" || true)
if [ -z "$shortcut_match" ]; then
  if [ -n "$expected_name" ]; then
    echo "error: Shortcut '$expected_name ($id)' not found" >&2
  else
    echo "error: Shortcut with ID '$id' not found" >&2
  fi
  exit 1
fi

if [ -n "$expected_name" ]; then
  actual_name="${shortcut_match%% ("${id}")}"
  if [ "$expected_name" != "$actual_name" ]; then
    echo "warn: Shortcut '$id' expected to be named '$expected_name' but was '$actual_name'" >&2
  fi
fi
