SCAN_RE='(^|[^[:alnum:]_-])(ack|ag|du|egrep|fd|fdfind|fgrep|find|grep|ls|ncdu|rg|ripgrep|tree)([[:space:]]|$)'
ROOT_RE='(^|[^[:alnum:]_./-])/nix(/store)?/*([^[:alnum:]_./-]|$)'
GLOB_RE='(^|[^[:alnum:]_./-])/nix/store/+[][*?]'

cmd="$(jq --raw-output '.tool_input.command // ""')" || exit 0
[ -n "$cmd" ] || exit 0

if [[ $cmd =~ $GLOB_RE ]] || { [[ $cmd =~ $SCAN_RE ]] && [[ $cmd =~ $ROOT_RE ]]; }; then
  jq --null-input '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Scanning all of /nix/store is banned. Read a specific store path instead."
    }
  }'
fi
