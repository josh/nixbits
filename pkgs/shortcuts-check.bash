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
    if [ $# -lt 2 ]; then
      echo "error: --name requires a value" >&2
      usage
      exit 1
    fi
    expected_name="$2"
    shift 2
    ;;
  --id)
    if [ $# -lt 2 ]; then
      echo "error: --id requires a value" >&2
      usage
      exit 1
    fi
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

# Capture the listing on its own so a shortcuts failure (e.g. denied
# automation access) aborts instead of reading as "shortcut not found".
shortcut_list=$(shortcuts list --show-identifiers)
shortcut_match=$(grep "(${id})" <<<"$shortcut_list" || true)
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
