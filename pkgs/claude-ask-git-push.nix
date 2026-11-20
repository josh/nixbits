{
  lib,
  writeShellApplication,
  runCommand,
  coreutils,
  jq,
}:
let
  claude-ask-git-push = writeShellApplication {
    name = "claude-ask-git-push";
    runtimeInputs = [ jq ];
    inheritPath = false;
    text = builtins.readFile ./claude-ask-git-push.bash;
    meta = {
      description = "Claude Code PreToolUse hook that asks before git and jj pushes";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  };
in
claude-ask-git-push.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        claude-ask-git-push = finalAttrs.finalPackage;
      in
      {
        conclusions =
          runCommand "test-conclusions"
            {
              nativeBuildInputs = [
                coreutils
                jq
                claude-ask-git-push
              ];
            }
            ''
              fail=0

              conclusion() {
                local out
                out=$(jq --null-input --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' |
                  claude-ask-git-push) || return 1
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

              assert_ask() { assert_conclusion ask "$1"; }
              assert_allow() { assert_conclusion allow "$1"; }

              assert_ignored() {
                local label=$1 out
                if ! out=$(printf '%s' "$2" | claude-ask-git-push 2>/dev/null); then
                  echo "FAIL exit!=0 -- $label" >&2
                  fail=1
                elif [ -n "$out" ]; then
                  echo "FAIL output  -- $label" >&2
                  fail=1
                fi
              }

              assert_ask 'git push'
              assert_ask 'git push origin main'
              assert_ask 'git -C ../x push'
              assert_ask 'git -c a=b push --force'
              assert_ask 'jj git push'
              assert_ask 'jj git push -b foo'
              assert_ask 'jj -R ../x git push'
              assert_ask 'jj --repository /r git push --all'
              assert_ask 'jj push'
              assert_ask 'cd x && git push'
              assert_ask 'jj describe -m x; jj git push'
              assert_ask 'GIT_TRACE=1 git push'
              assert_ask '/usr/bin/git push'

              assert_allow 'git status'
              assert_allow 'git commit -m "fix push logic"'
              assert_allow 'git log --grep push'
              assert_allow 'git stash push'
              assert_allow 'jj git fetch'
              assert_allow 'jj describe -m "push later"'
              assert_allow 'gh pr merge 1'
              assert_allow 'echo git push'
              assert_allow 'rg "git push" docs/'

              assert_ignored "malformed json" 'not json at all{{{'
              assert_ignored "empty stdin" ""
              assert_ignored "null tool_input" '{"tool_input":null}'
              assert_ignored "numeric command" '{"tool_input":{"command":42}}'
              assert_ignored "read payload" '{"tool_name":"Read","tool_input":{"file_path":"git push"}}'

              reason=$(jq --null-input --arg c "git push" '{tool_input:{command:$c}}' |
                claude-ask-git-push |
                jq --raw-output '.hookSpecificOutput | select(.hookEventName == "PreToolUse") | .permissionDecisionReason')
              if [ -z "$reason" ]; then
                echo "FAIL ask payload shape" >&2
                fail=1
              fi

              if [ "$fail" -ne 0 ]; then
                exit 1
              fi
              echo "ok: 22 commands, 5 payloads"

              touch $out
            '';
      };
  }
)
