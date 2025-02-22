if [ -z "${RUNNER_ROOT:-}" ]; then
  echo "error: RUNNER_ROOT must be set" >&2
  exit 1
fi

if [ -f "$RUNNER_ROOT/.config.hash" ]; then
  if [ "$(cat "$RUNNER_ROOT/.config.hash")" = "$CONFIG_HASH" ]; then
    echo "Configuration already up-to-date" >&2
    exit 0
  else
    echo "Removing outdated configuration" >&2
    github-runner-config-remove
    rm -f "$RUNNER_ROOT/.config.hash"
  fi
fi

"$GITHUB_RUNNER_PATH/bin/config.sh" "$@"
echo "$CONFIG_HASH" >"$RUNNER_ROOT/.config.hash"

if [ ! -f "$RUNNER_ROOT/.credentials" ]; then
  echo "error: failed to configure runner" >&2
  exit 1
fi
