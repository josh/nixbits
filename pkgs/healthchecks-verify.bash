usage() {
  cat <<EOF
Usage: $(basename "$0") [--api-url URL] [--api-key KEY] CHECKS_PATH

Verify healthchecks configuration against a Healthchecks.io instance.

Arguments:
  CHECKS_PATH       A file or directory of check slugs.

Options:
  --api-url URL     Healthchecks API URL (default: https://healthchecks.io)
  --api-key KEY     Healthchecks API key
  --verbose         Enable verbose output
EOF
  exit 1
}

HC_API_URL=${HC_API_URL:-"https://healthchecks.io"}
HC_API_KEY=${HC_API_KEY:-""}
HC_API_KEY_FILE=${HC_API_KEY_FILE:-""}
HC_API_KEY_COMMAND=${HC_API_KEY_COMMAND:-""}
HC_CHECKS_PATH=${HC_CHECKS_PATH:-""}
verbose=0

while [[ $# -gt 0 ]]; do
  case $1 in
  --api-url)
    HC_API_URL="$2"
    shift 2
    ;;
  --api-key)
    HC_API_KEY="$2"
    shift 2
    ;;
  --api-key-file)
    HC_API_KEY_FILE="$2"
    shift 2
    ;;
  --api-key-command)
    HC_API_KEY_COMMAND="$2"
    shift 2
    ;;
  --verbose)
    verbose=1
    shift
    ;;
  *)
    HC_CHECKS_PATH="$1"
    shift
    ;;
  esac
done

if [ -z "$HC_API_KEY" ] && [ -n "$HC_API_KEY_FILE" ]; then
  HC_API_KEY=$(cat "$HC_API_KEY_FILE")
elif [ -z "$HC_API_KEY" ] && [ -n "$HC_API_KEY_COMMAND" ]; then
  HC_API_KEY=$(eval "$HC_API_KEY_COMMAND")
fi

if [ -z "$HC_API_KEY" ]; then
  echo "error: HC_API_KEY is required" >&2
  usage
fi

if [ -z "$HC_CHECKS_PATH" ]; then
  echo "error: CHECKS_PATH is required" >&2
  usage
fi

if [ ! -e "$HC_CHECKS_PATH" ]; then
  echo "error: CHECKS_PATH does not exist" >&2
  exit 1
fi

hc_list_checks() {
  local url="${HC_API_URL%/}/api/v3/checks/"
  curl --fail --show-error --silent \
    --header "X-Api-Key: $HC_API_KEY" \
    "$url" |
    jq --raw-output '.checks[].slug'
}

config_slugs() {
  if [ -f "$1" ]; then
    jq --raw-output 'if type == "array" then .[].slug else .slug end' "$1"
  else
    while IFS= read -r file; do
      config_slugs "$file"
    done < <(find -L "$1" -type f)
  fi
}

if ! slugs=$(hc_list_checks); then
  echo "error: failed to fetch checks" >&2
  exit 1
fi

code=0
mapfile -t check_slugs < <(config_slugs "$HC_CHECKS_PATH")

for slug in "${check_slugs[@]}"; do
  if ! echo "$slugs" | grep -q "^${slug}$"; then
    echo "healthchecks: $slug missing" >&2
    code=1
  else
    if [ $verbose -eq 1 ]; then
      echo "healthchecks: $slug ok" >&2
    fi
  fi
done

exit $code
