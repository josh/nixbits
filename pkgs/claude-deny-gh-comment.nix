{
  lib,
  writeShellApplication,
  runCommand,
  coreutils,
  jq,
}:
let
  claude-deny-gh-comment = writeShellApplication {
    name = "claude-deny-gh-comment";
    runtimeInputs = [ jq ];
    inheritPath = false;
    text = builtins.readFile ./claude-deny-gh-comment.bash;
    meta = {
      description = "Claude Code PreToolUse hook that denies posting GitHub comments with gh";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  };
in
claude-deny-gh-comment.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        claude-deny-gh-comment = finalAttrs.finalPackage;
      in
      {
        conclusions =
          runCommand "test-conclusions"
            {
              nativeBuildInputs = [
                coreutils
                jq
                claude-deny-gh-comment
              ];
            }
            ''
              fail=0

              conclusion() {
                local out
                out=$(jq --null-input --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' |
                  claude-deny-gh-comment) || return 1
                if [ -z "$out" ]; then
                  echo allow
                else
                  printf '%s' "$out" | jq --raw-output '.hookSpecificOutput.permissionDecision // "?"'
                fi
              }

              assert_conclusion() {
                local want=$1 cmd=$2 got
                if ! got=$(conclusion "$cmd"); then
                  echo "FAIL exit!=0            -- $cmd" >&2
                  fail=1
                elif [ "$got" != "$want" ]; then
                  echo "FAIL want=$want got=$got -- $cmd" >&2
                  fail=1
                fi
              }

              assert_deny() { assert_conclusion deny "$1"; }
              assert_allow() { assert_conclusion allow "$1"; }

              assert_ignored() {
                local label=$1 out
                if ! out=$(printf '%s' "$2" | claude-deny-gh-comment 2>/dev/null); then
                  echo "FAIL exit!=0 -- $label" >&2
                  fail=1
                elif [ -n "$out" ]; then
                  echo "FAIL output  -- $label" >&2
                  fail=1
                fi
              }

              assert_deny 'gh pr comment 1 -b x'
              assert_deny 'gh issue comment 2 --body-file f'
              assert_deny 'gh pr comment --edit-last -b x'
              assert_deny 'gh pr close 123 --comment "dup"'
              assert_deny 'gh pr close 123 -c dup'
              assert_deny 'gh pr close --comment=x 1'
              assert_deny 'gh issue close 5 -c x'
              assert_deny 'gh -R o/r pr close 9 --comment x'
              assert_deny 'gh pr close 9 --repo o/r -c x'
              assert_deny 'cd x && gh pr close 1 -c y'
              assert_deny 'git push; gh pr close 1 --comment y'
              assert_deny 'GH_TOKEN=x gh issue comment 3 -b hi'
              assert_deny '/opt/homebrew/bin/gh pr comment 1 -b x'
              assert_deny 'gh pr review 1 --comment -b x'
              assert_deny 'gh pr review 1 --approve -b lgtm'
              assert_deny 'gh pr review 1 --request-changes --body-file f'

              assert_allow 'gh pr close 123'
              assert_allow 'gh pr close 123 --delete-branch'
              assert_allow 'gh issue close 5 --reason completed'
              assert_allow 'gh pr view 1 --comments'
              assert_allow 'gh issue view 2 --comments'
              assert_allow 'gh pr review 1 --approve'
              assert_allow 'gh pr list'
              assert_allow 'gh pr create --title x --body "add comment support"'
              assert_allow 'gh api repos/o/r/issues/1/comments'
              assert_allow 'git commit -m "comment"'
              assert_allow 'echo gh pr comment'
              assert_allow 'rg "gh pr comment" docs/'

              assert_ignored "malformed json" 'not json at all{{{'
              assert_ignored "empty stdin" ""
              assert_ignored "null tool_input" '{"tool_input":null}'
              assert_ignored "numeric command" '{"tool_input":{"command":42}}'
              assert_ignored "read payload" '{"tool_name":"Read","tool_input":{"file_path":"gh pr comment"}}'

              reason=$(jq --null-input --arg c "gh pr comment 1 -b x" '{tool_input:{command:$c}}' |
                claude-deny-gh-comment |
                jq --raw-output '.hookSpecificOutput | select(.hookEventName == "PreToolUse") | .permissionDecisionReason')
              if [ -z "$reason" ]; then
                echo "FAIL deny payload shape" >&2
                fail=1
              fi

              if [ "$fail" -ne 0 ]; then
                exit 1
              fi
              echo "ok: 28 commands, 5 payloads"

              touch $out
            '';
      };
  }
)
