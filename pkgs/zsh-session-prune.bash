shopt -s nullglob

sessions=("$HOME/.zsh_sessions"/*.history)
[ "${#sessions[@]}" -eq 0 ] && exit 0

histutils \
  --output-format zsh \
  --output "$HOME/.zsh_history" \
  "$HOME/.zsh_history" "$HOME/.zsh_sessions"/*.history
rm "$HOME/.zsh_sessions"/*.history "$HOME/.zsh_sessions"/*.session
