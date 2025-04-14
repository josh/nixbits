available_systems="aarch64-darwin aarch64-linux x86_64-linux"
shell_flag="--no-shell"
args=()

number=""
systems=""
result_flag=""

while [[ $# -gt 0 ]]; do
  case "$1" in
  --dry-run)
    result_flag="--print-result"
    shift
    ;;
  --systems)
    systems="$2"
    shift 2
    ;;
  --shell)
    shell_flag=""
    shift
    ;;
  -*)
    args+=("$1")
    shift
    ;;
  *)
    if [ -z "$number" ]; then
      number="$1"
      shift
    else
      echo "error: unexpected argument: $1" >&2
      exit 1
    fi
    ;;
  esac
done

if [ -z "$number" ]; then
  number=$(gum input --placeholder "PR number")
fi
if [ -z "$number" ]; then
  echo "error: PR number is required" >&2
  exit 1
fi

if [ -z "$systems" ]; then
  systems="$(echo "$available_systems" |
    gum choose \
      --input-delimiter=" " \
      --output-delimiter=" " \
      --no-limit \
      --selected "*" \
      --header "Systems")"
fi
if [ -z "$systems" ]; then
  echo "error: systems are required" >&2
  exit 1
fi

if [ -z "$result_flag" ]; then
  if gum confirm --default=false "Post result?"; then
    result_flag="--post-result"
  else
    result_flag="--print-result"
  fi
fi

if [ -d "$HOME/Developer/nixpkgs" ]; then
  cd "$HOME/Developer/nixpkgs" || true
fi

set -o xtrace
exec nixpkgs-review pr \
  --systems "$systems" \
  $shell_flag \
  $result_flag \
  "$number" \
  "${args[@]}"
