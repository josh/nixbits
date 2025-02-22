if [ -z "${RUNNER_ROOT:-}" ]; then
  echo "error: RUNNER_ROOT must be set" >&2
  exit 1
fi

if [ -n "${RUNNER_USE_GH_TOKEN:-}" ]; then
  RUNNER_PAT=$(gh auth token)
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

declare -a config_opts=()
if [ -n "${RUNNER_URL:-}" ]; then
  config_opts+=(--url "$RUNNER_URL")
fi
if [ -n "${RUNNER_PAT:-}" ]; then
  config_opts+=(--pat "$RUNNER_PAT")
fi
if [ -n "${RUNNER_NAME:-}" ]; then
  config_opts+=(--name "$RUNNER_NAME")
fi
if [ -n "${RUNNER_GROUP:-}" ]; then
  config_opts+=(--runnergroup "$RUNNER_GROUP")
fi
if [ -n "${RUNNER_LABELS:-}" ]; then
  config_opts+=(--labels "$RUNNER_LABELS")
fi
if [ -n "${RUNNER_WORK:-}" ]; then
  config_opts+=(--work "$RUNNER_WORK")
fi
if [ -n "${RUNNER_EPHEMERAL:-}" ]; then
  config_opts+=(--ephemeral "$RUNNER_EPHEMERAL")
fi

"$GITHUB_RUNNER_PATH/bin/config.sh" \
  --unattended \
  --disableupdate \
  --replace \
  "${config_opts[@]}" \
  "$@"
echo "$CONFIG_HASH" >"$RUNNER_ROOT/.config.hash"

if [ ! -f "$RUNNER_ROOT/.credentials" ]; then
  echo "error: failed to configure runner" >&2
  exit 1
fi
