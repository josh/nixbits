[ -n "$GITHUB_OUTPUT" ]
[ -n "$GH_TOKEN" ]
[ -n "$PR_URL" ]
[ -n "$BASE_FLAKE" ]
[ -n "$HEAD_FLAKE" ]

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Compare a single flake output attr between base and head.
# Returns 0 when unchanged, 1 when changed, 2 on evaluation error.
compare_attr() {
  local attr="$1"
  local base_out="$tmpdir/base.$attr"
  local head_out="$tmpdir/head.$attr"

  nix eval --json "${BASE_FLAKE}#${attr}" >"$base_out" &
  local pid_a=$!
  nix eval --json "${HEAD_FLAKE}#${attr}" >"$head_out" &
  local pid_b=$!

  wait "$pid_a" || {
    echo "::error::failed to evaluate ${BASE_FLAKE}#${attr}" >&2
    return 2
  }
  wait "$pid_b" || {
    echo "::error::failed to evaluate ${HEAD_FLAKE}#${attr}" >&2
    return 2
  }

  echo "::group::${attr}"
  local rc=0
  jd -color "$base_out" "$head_out" || rc=$?
  echo "::endgroup::"
  return "$rc"
}

changed=false
eval_error=false
for attr in packages checks; do
  if compare_attr "$attr"; then
    continue
  else
    rc=$?
    if [ "$rc" -eq 2 ]; then
      eval_error=true
    else
      changed=true
    fi
  fi
done

if [ "$eval_error" = true ]; then
  echo "status=error" >>"$GITHUB_OUTPUT"
  exit 1
fi

if [ "$changed" = true ]; then
  echo "status=change" >>"$GITHUB_OUTPUT"
  if ! gh pr edit "$PR_URL" --remove-label "noop" >/dev/null; then
    echo "::warning::Error removing label" >&2
  fi
  exit 0
else
  echo "status=no-change" >>"$GITHUB_OUTPUT"
  if ! gh pr edit "$PR_URL" --add-label "noop" >/dev/null; then
    echo "::warning::Error adding label" >&2
  fi
  echo "::notice::No changes detected" >&2
  exit 1
fi
