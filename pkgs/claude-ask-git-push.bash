CMD_RE='^[[:space:]({]*(sudo[[:space:]]+|env[[:space:]]+|command[[:space:]]+|exec[[:space:]]+|[[:alpha:]_][[:alnum:]_]*=[^[:space:]]*[[:space:]]+)*([^[:space:]]*/)?(git|jj)[[:space:]]+(.*)$'

cmd="$(jq --raw-output '.tool_input.command // ""')" || exit 0
[ -n "$cmd" ] || exit 0

pushes() {
  local tool=$1 tok skip=0
  local -a args words=()
  read -ra args <<<"$2"

  for tok in "${args[@]}"; do
    if [ "$skip" -eq 1 ]; then
      skip=0
    elif [[ $tool == git && ($tok == -C || $tok == -c || $tok == --git-dir || $tok == --work-tree || $tok == --namespace) ]] ||
      [[ $tool == jj && ($tok == -R || $tok == --repository || $tok == --at-op || $tok == --at-operation ||
        $tok == --config || $tok == --config-file || $tok == --color) ]]; then
      skip=1
    elif [[ $tok != -* ]]; then
      words+=("$tok")
      [ "${#words[@]}" -lt 2 ] || break
    fi
  done

  [[ ${words[0]:-} == push ]] && return 0
  [[ $tool == jj && ${words[0]:-} == git && ${words[1]:-} == push ]]
}

cmd=${cmd//&&/$'\n'}
cmd=${cmd//||/$'\n'}
cmd=${cmd//;/$'\n'}
cmd=${cmd//|/$'\n'}

while IFS= read -r seg; do
  if [[ $seg =~ $CMD_RE ]] && pushes "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}"; then
    jq --null-input '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: "Pushing is never automatic and always needs confirmation."
      }
    }'
    exit 0
  fi
done <<<"$cmd"
