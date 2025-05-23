shopt -s nullglob

sessions=("$HOME/.zsh_sessions"/*.history)
[ "${#sessions[@]}" -eq 0 ] && exit 0

set -o xtrace

zsh-history-merge "$HOME/.zsh_history" "$HOME/.zsh_sessions"/*.history | sponge -a "$HOME/.zsh_history"
rm "$HOME/.zsh_sessions"/*.history "$HOME/.zsh_sessions"/*.session
