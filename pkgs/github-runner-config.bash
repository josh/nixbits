if [ -z "${RUNNER_ROOT:-}" ]; then
  echo "error: RUNNER_ROOT must be set" >&2
  exit 1
fi

if [ -n "${RUNNER_USE_GH_TOKEN:-}" ] && [ -z "${RUNNER_PAT:-}" ]; then
  RUNNER_PAT=$(gh auth token)
elif [ -n "${CREDENTIALS_DIRECTORY:-}" ] && [ -z "${RUNNER_PAT:-}" ]; then
  if [ -f "${CREDENTIALS_DIRECTORY}/GITHUB_TOKEN" ]; then
    RUNNER_PAT=$(cat "${CREDENTIALS_DIRECTORY}/GITHUB_TOKEN")
  elif [ -f "${CREDENTIALS_DIRECTORY}/GH_TOKEN" ]; then
    RUNNER_PAT=$(cat "${CREDENTIALS_DIRECTORY}/GH_TOKEN")
  elif [ -f "${CREDENTIALS_DIRECTORY}/github-token" ]; then
    RUNNER_PAT=$(cat "${CREDENTIALS_DIRECTORY}/github-token")
  fi
fi

declare -a config_opts=(--unattended --disableupdate --replace)
if [ -n "${RUNNER_URL:-}" ]; then
  config_opts+=(--url "$RUNNER_URL")
fi
if [ -n "${RUNNER_PAT:-}" ]; then
  config_opts+=(--pat "$RUNNER_PAT")
fi
if [ -n "${RUNNER_NAME:-}" ]; then
  config_opts+=(--name "$RUNNER_NAME")
fi
if [ -n "${RUNNER_RUNNERGROUP:-}" ]; then
  config_opts+=(--runnergroup "$RUNNER_RUNNERGROUP")
fi
if [ -n "${RUNNER_LABELS:-}" ]; then
  config_opts+=(--labels "$RUNNER_LABELS")
fi
if [ -n "${RUNNER_WORK:-}" ]; then
  config_opts+=(--work "$RUNNER_WORK")
fi
if [ -n "${RUNNER_EPHEMERAL:-}" ]; then
  config_opts+=(--ephemeral)
fi

for arg in "$@"; do
  config_opts+=("$arg")
done

# Hash the configuration without the PAT: the token rotates on every
# gh auth token refresh and must not force a reconfiguration.
declare -a hash_opts=()
skip_next=false
for opt in "${config_opts[@]}"; do
  if [ "$skip_next" = true ]; then
    skip_next=false
    continue
  fi
  if [ "$opt" = "--pat" ]; then
    skip_next=true
    continue
  fi
  hash_opts+=("$opt")
done
expected_config_hash="$(printf '%s\n' "${hash_opts[@]}" | sha256sum | cut -d' ' -f1)"
actual_config_hash=""
if [ -f "$RUNNER_ROOT/.config.hash" ]; then
  actual_config_hash="$(cat "$RUNNER_ROOT/.config.hash")"
fi

if [ -f "$RUNNER_ROOT/.credentials" ] && [ -f "$RUNNER_ROOT/.runner" ]; then
  if [ ! -f "$RUNNER_ROOT/.config.hash" ]; then
    echo "Configured, but missing config hash" >&2
    github-runner-config-remove
  elif [ "$actual_config_hash" != "$expected_config_hash" ]; then
    echo "Removing outdated configuration" >&2
    github-runner-config-remove
    rm -f "$RUNNER_ROOT/.config.hash"
  else
    echo "Configuration already up-to-date" >&2
    exit 0
  fi
fi

"$GITHUB_RUNNER_PATH/bin/config.sh" "${config_opts[@]}"
echo "$expected_config_hash" >"$RUNNER_ROOT/.config.hash"

if [ ! -f "$RUNNER_ROOT/.credentials" ]; then
  echo "error: failed to configure runner" >&2
  exit 1
fi
