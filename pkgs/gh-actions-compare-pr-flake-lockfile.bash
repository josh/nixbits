# Exit codes:
#   0 - flake outputs changed
#   1 - no change
#   2 - evaluation error, or missing configuration

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

# Compare only one system's outputs instead of every system the flake declares.
# Unset compares all systems. Set to "current", or to a literal system such as
# "x86_64-linux", when the flake uses import from derivation that can't be built
# here. This trades coverage for termination: a lockfile bump that only affects
# other systems will then report no-change.
SYSTEM="${SYSTEM-}"

# Evaluation can trigger a build through import from derivation. Allow that when
# it can succeed locally or from a substituter, but never hand it to a remote
# builder. That path retries forever when the builder is busy or unreachable,
# instead of failing.
nix_eval_options=(
  --builders ''
  --option connect-timeout 5
  --option stalled-download-timeout 90
)

# No nix setting bounds evaluation wall clock time. build-timeout and
# max-silent-time only apply once a build is already running.
eval_timeout=600

if [ "$SYSTEM" = "current" ]; then
  SYSTEM=$(nix eval --raw --impure --expr 'builtins.currentSystem')
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ignore_nix="[ "
for name in $IGNORE_CHECKS; do
  ignore_nix+="\"$name\" "
done
ignore_nix+="]"

# Scoping to a system drops a level of nesting, so the filter changes shape.
if [ -n "$SYSTEM" ]; then
  attr_suffix=".$SYSTEM"
  checks_apply="names: builtins.removeAttrs names ${ignore_nix}"
else
  attr_suffix=""
  checks_apply="cs: builtins.mapAttrs (_: names: builtins.removeAttrs names ${ignore_nix}) cs"
fi

eval_attr() {
  local flake="$1" attr="$2" out="$3"
  shift 3
  local errfile="${out}.err"
  local rc=0

  timeout --signal=TERM --kill-after=30s "$eval_timeout" \
    nix eval --json "${nix_eval_options[@]}" "${flake}#${attr}" "$@" \
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

  if grep -qE "Cannot build|Unable to start any build|allow-import-from-derivation" "$errfile"; then
    echo "::error::${flake}#${attr} needs a build during evaluation (import from derivation) that can't run here" >&2
  fi

  cat "$errfile" >&2
  return 1
}

# Set when any evaluation returned something, so that a SYSTEM the flake doesn't
# declare can't look like an empty diff.
any_output=false

# Compare a single flake output attr between base and head.
# Returns 0 when unchanged, 1 when changed, 2 on evaluation error.
compare_attr() {
  local attr="$1"
  shift
  local base_out="$tmpdir/base.$attr"
  local head_out="$tmpdir/head.$attr"

  eval_attr "$BASE_FLAKE" "$attr" "$base_out" "$@" &
  local pid_a=$!
  eval_attr "$HEAD_FLAKE" "$attr" "$head_out" "$@" &
  local pid_b=$!

  local rc_a=0 rc_b=0
  wait "$pid_a" || rc_a=$?
  wait "$pid_b" || rc_b=$?

  if [ "$rc_a" -ne 0 ]; then
    echo "::error::failed to evaluate ${BASE_FLAKE}#${attr}" >&2
  fi
  if [ "$rc_b" -ne 0 ]; then
    echo "::error::failed to evaluate ${HEAD_FLAKE}#${attr}" >&2
  fi
  if [ "$rc_a" -ne 0 ] || [ "$rc_b" -ne 0 ]; then
    return 2
  fi

  local content
  content=$(cat "$base_out")
  if [ "$content" != "{}" ]; then
    any_output=true
  fi
  content=$(cat "$head_out")
  if [ "$content" != "{}" ]; then
    any_output=true
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
compare_attr "packages${attr_suffix}" || rc=$?
classify "$rc"

rc=0
compare_attr "checks${attr_suffix}" --apply "$checks_apply" || rc=$?
classify "$rc"

if [ -n "$SYSTEM" ] && [ "$any_output" = false ] && [ "$eval_error" = false ]; then
  echo "::error::no packages or checks for system ${SYSTEM}; is it declared by the flake?" >&2
  eval_error=true
fi

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
