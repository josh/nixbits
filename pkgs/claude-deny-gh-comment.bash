GH_RE='^[[:space:]({]*(sudo[[:space:]]+|env[[:space:]]+|command[[:space:]]+|exec[[:space:]]+|[[:alpha:]_][[:alnum:]_]*=[^[:space:]]*[[:space:]]+)*([^[:space:]]*/)?gh[[:space:]]+(.*)$'

cmd="$(jq --raw-output '.tool_input.command // ""')" || exit 0
[ -n "$cmd" ] || exit 0

posts_comment() {
  local -a args
  local words=() skip=0 tok
  read -ra args <<<"$1"

  for tok in "${args[@]}"; do
    if [ "$skip" -eq 1 ]; then
      skip=0
    elif [[ $tok == -R || $tok == --repo || $tok == --hostname ]]; then
      skip=1
    elif [[ $tok != -* ]] && [ "${#words[@]}" -lt 2 ]; then
      words+=("$tok")
    fi
  done

  [[ ${words[0]:-} == pr || ${words[0]:-} == issue ]] || return 1

  case "${words[1]:-}" in
  comment) return 0 ;;
  close)
    for tok in "${args[@]}"; do
      [[ $tok == --comment || $tok == --comment=* || $tok == -c* ]] && return 0
    done
    ;;
  review)
    for tok in "${args[@]}"; do
      [[ $tok == --comment || $tok == -c* || $tok == --body || $tok == --body=* || $tok == -b* ||
        $tok == --body-file || $tok == --body-file=* || $tok == -F* ]] && return 0
    done
    ;;
  esac
  return 1
}

cmd=${cmd//&&/$'\n'}
cmd=${cmd//||/$'\n'}
cmd=${cmd//;/$'\n'}
cmd=${cmd//|/$'\n'}

while IFS= read -r seg; do
  if [[ $seg =~ $GH_RE ]] && posts_comment "${BASH_REMATCH[3]}"; then
    jq --null-input '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "Posting GitHub comments with gh is banned."
      }
    }'
    exit 0
  fi
done <<<"$cmd"
