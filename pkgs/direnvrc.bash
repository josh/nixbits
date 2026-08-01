layout_uv() {
  watch_file .python-version pyproject.toml uv.lock
  if ! "@uv@" sync --frozen; then
    log_error "uv sync failed"
    return 1
  fi

  venv_path="$(expand_path "${UV_PROJECT_ENVIRONMENT:-.venv}")"
  if [[ -e $venv_path ]]; then
    # direnv cannot export PS1 and starship redraws the prompt anyway
    export VIRTUAL_ENV_DISABLE_PROMPT=1
    # shellcheck source=/dev/null
    source "$venv_path/bin/activate"
  fi
}
