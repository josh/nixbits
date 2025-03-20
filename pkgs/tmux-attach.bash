sessions=()
mapfile -t sessions < <(tmux list-sessions -F "#{session_name}" -f "#{?session_attached,0,1}" 2>/dev/null)

if [ ${#sessions[@]} -gt 0 ]; then
  exec tmux attach-session -t "${sessions[0]}"
else
  exec tmux new-session
fi
