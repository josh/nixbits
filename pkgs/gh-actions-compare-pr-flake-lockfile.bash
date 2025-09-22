[ -n "$GITHUB_OUTPUT" ]
[ -n "$GH_TOKEN" ]
[ -n "$PR_URL" ]
[ -n "$BASE_FLAKE" ]
[ -n "$HEAD_FLAKE" ]

a_out=$(mktemp)
b_out=$(mktemp)

trap 'rm -f "$a_out" "$b_out"' EXIT

nix eval --json "${BASE_FLAKE}#packages" >"$a_out" &
pid_a=$!

nix eval --json "${HEAD_FLAKE}#packages" >"$b_out" &
pid_b=$!

wait $pid_a
status_a=$?
wait $pid_b
status_b=$?

if [ $status_a -ne 0 ]; then
  echo "::error::failed to evaluate ${BASE_FLAKE}#packages" >&2
  echo "status=error" >>"$GITHUB_OUTPUT"
  exit $status_a
fi

if [ $status_b -ne 0 ]; then
  echo "::error::failed to evaluate ${HEAD_FLAKE}#packages" >&2
  echo "status=error" >>"$GITHUB_OUTPUT"
  exit $status_b
fi

if jd -color "$a_out" "$b_out"; then
  echo "status=no-change" >>"$GITHUB_OUTPUT"
  if ! gh pr edit "$PR_URL" --add-label "noop" >/dev/null; then
    echo "::warning::Error adding label" >&2
  fi
  echo "::notice::No changes detected" >&2
  exit 1
else
  echo "status=change" >>"$GITHUB_OUTPUT"
  if ! gh pr edit "$PR_URL" --remove-label "noop" >/dev/null; then
    echo "::warning::Error removing label" >&2
  fi
  exit 0
fi
