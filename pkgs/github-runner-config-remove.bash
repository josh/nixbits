if [ -z "${RUNNER_ROOT:-}" ]; then
  echo "error: RUNNER_ROOT must be set" >&2
  exit 1
fi

if [ -n "${RUNNER_USE_GH_TOKEN:-}" ] && [ -z "${RUNNER_PAT:-}" ]; then
  RUNNER_PAT=$(gh auth token)
fi

"$GITHUB_RUNNER_PATH/bin/config.sh" remove --pat "$RUNNER_PAT"
rm -f "$RUNNER_ROOT/.config.hash"
