require_env() {
  local name="$1"
  if [ -z "${!name-}" ]; then
    echo "::error::$name is not set" >&2
    exit 2
  fi
}

require_env GITHUB_OUTPUT
require_env GH_TOKEN
require_env PR_URL
require_env BASE_FLAKE
require_env HEAD_FLAKE

IGNORE_CHECKS="${IGNORE_CHECKS-formatting}"

eval_timeout=600

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ignore_nix="[ "
for name in $IGNORE_CHECKS; do
  ignore_nix+="\"$name\" "
done
ignore_nix+="]"
checks_apply="cs: builtins.mapAttrs (_: names: builtins.removeAttrs names ${ignore_nix}) cs"

eval_attr() {
  local flake="$1" attr="$2" out="$3"
  shift 3
  local errfile="${out}.err"
  local rc=0

  timeout --signal=TERM --kill-after=30s "$eval_timeout" \
    nix eval --json "${flake}#${attr}" "$@" \
    >"$out" 2>"$errfile" || rc=$?

  if [ "$rc" -eq 0 ]; then
    return 0
  fi

  if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
    echo "::error::timed out after ${eval_timeout}s evaluating ${flake}#${attr}" >&2
    cat "$errfile" >&2
    return 1
  fi

  if grep -q "does not provide attribute" "$errfile"; then
    echo "{}" >"$out"
    return 0
  fi

  cat "$errfile" >&2
  return 1
}

# Compare a single flake output attr between base and head.
# Returns 0 when unchanged, 1 when changed, 2 on evaluation error.
compare_attr() {
  local attr="$1"
  shift
  local base_out="$tmpdir/base.$attr"
  local head_out="$tmpdir/head.$attr"

  local rc_a=0 rc_b=0
  eval_attr "$BASE_FLAKE" "$attr" "$base_out" "$@" || rc_a=$?
  eval_attr "$HEAD_FLAKE" "$attr" "$head_out" "$@" || rc_b=$?

  if [ "$rc_a" -ne 0 ]; then
    echo "::error::failed to evaluate ${BASE_FLAKE}#${attr}" >&2
  fi
  if [ "$rc_b" -ne 0 ]; then
    echo "::error::failed to evaluate ${HEAD_FLAKE}#${attr}" >&2
  fi
  if [ "$rc_a" -ne 0 ] || [ "$rc_b" -ne 0 ]; then
    return 2
  fi

  echo "::group::${attr}"
  local rc=0
  jd -color "$base_out" "$head_out" || rc=$?
  echo "::endgroup::"
  return "$rc"
}

remove_noop_label() {
  if ! gh pr edit "$PR_URL" --remove-label "noop" >/dev/null; then
    echo "::warning::Error removing label" >&2
  fi
}

changed=false
eval_error=false
classify() {
  case "$1" in
  0) ;;
  2) eval_error=true ;;
  *) changed=true ;;
  esac
}

rc=0
compare_attr packages || rc=$?
classify "$rc"

rc=0
compare_attr checks --apply "$checks_apply" || rc=$?
classify "$rc"

if [ "$eval_error" = true ]; then
  echo "status=error" >>"$GITHUB_OUTPUT"
  remove_noop_label
  exit 2
fi

if [ "$changed" = true ]; then
  echo "status=change" >>"$GITHUB_OUTPUT"
  remove_noop_label
  exit 0
else
  echo "status=no-change" >>"$GITHUB_OUTPUT"
  if ! gh pr edit "$PR_URL" --add-label "noop" >/dev/null; then
    echo "::warning::Error adding label" >&2
  fi
  echo "::notice::No changes detected" >&2
  exit 1
fi
