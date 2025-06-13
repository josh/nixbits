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

"$GITHUB_RUNNER_PATH/bin/config.sh" remove --pat "$RUNNER_PAT"
rm -f "$RUNNER_ROOT/.config.hash"
