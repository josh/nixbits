layout_uv() {
  watch_file .python-version pyproject.toml uv.lock
  "@uv@" sync --frozen || true

  venv_path="$(expand_path "${UV_PROJECT_ENVIRONMENT:-.venv}")"
  if [[ -e $venv_path ]]; then
    # shellcheck source=/dev/null
    source "$venv_path/bin/activate"
  fi
}
