shopt -s nullglob

sessions=("$HOME/.zsh_sessions"/*.history)
session_meta=("$HOME/.zsh_sessions"/*.session)
[ "${#sessions[@]}" -eq 0 ] && exit 0

histutils \
  --output-format zsh \
  --fix \
  --tail 50000 \
  --output "$HOME/.zsh_history" \
  "$HOME/.zsh_history" "${sessions[@]}"
rm "${sessions[@]}"
[ "${#session_meta[@]}" -eq 0 ] || rm "${session_meta[@]}"
