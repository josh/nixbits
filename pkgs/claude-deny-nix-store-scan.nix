{
  lib,
  writeShellApplication,
  runCommand,
  coreutils,
  jq,
}:
let
  claude-deny-nix-store-scan = writeShellApplication {
    name = "claude-deny-nix-store-scan";
    runtimeInputs = [ jq ];
    inheritPath = false;
    text = builtins.readFile ./claude-deny-nix-store-scan.bash;
    meta = {
      description = "Claude Code PreToolUse hook that denies whole-store Nix scans";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  };
in
claude-deny-nix-store-scan.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        claude-deny-nix-store-scan = finalAttrs.finalPackage;
      in
      {
        conclusions =
          runCommand "test-conclusions"
            {
              nativeBuildInputs = [
                coreutils
                jq
                claude-deny-nix-store-scan
              ];
            }
            ''
              fail=0

              conclusion() {
                local out
                out=$(jq --null-input --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' |
                  claude-deny-nix-store-scan) || return 1
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
                if ! out=$(printf '%s' "$2" | claude-deny-nix-store-scan 2>/dev/null); then
                  echo "FAIL exit!=0 -- $label" >&2
                  fail=1
                elif [ -n "$out" ]; then
                  echo "FAIL output  -- $label" >&2
                  fail=1
                fi
              }

              assert_deny 'find /nix/store -name foo'
              assert_deny 'find /nix/store/'
              assert_deny 'sudo find /nix/store'
              assert_deny 'find /nix/ -name x'
              assert_deny 'grep -r pattern /nix/store'
              assert_deny 'grep -rn foo /nix/store 2>/dev/null'
              assert_deny 'rg pattern /nix/store'
              assert_deny 'rg --files /nix/store/'
              assert_deny 'fd . /nix/store'
              assert_deny 'fdfind . /nix/store'
              assert_deny 'du -sh /nix/store'
              assert_deny 'sudo du -sh /nix'
              assert_deny 'tree /nix/store'
              assert_deny 'ls /nix/store'
              assert_deny 'ls -d /nix/store'
              assert_deny 'ls "/nix/store"'
              assert_deny 'ls /nix/store | grep foo'
              assert_deny 'cd /nix/store && ls'
              assert_deny 'cat /nix/store/*'
              assert_deny 'ls /nix/store/*-foo'
              assert_deny 'find /nix/store/*/bin -name x'
              assert_deny 'grep -l foo /nix/store/*-source/README'
              assert_deny "find /nix -name '*.so'"

              assert_allow 'find /nix/store/abc123-foo/share -type f'
              assert_allow 'grep -r pattern /nix/store/abc123-foo'
              assert_allow 'rg needle /nix/store/wp5hh39-source/pkgs'
              assert_allow 'ls /nix/store/abc123-foo'
              assert_allow 'ls -R /nix/store/abc123-foo'
              assert_allow 'ls -la /nix/store/abc123-foo/lib/*.dylib'
              assert_allow 'du -sh /nix/store/abc-foo'
              assert_allow 'cat /nix/store/abc123-foo/bin/x'
              assert_allow 'readlink -f /nix/store/abc-foo'
              assert_allow 'nix path-info /nix/store/abc-foo'
              assert_allow 'nix-store --query --requisites /nix/store/abc-foo'
              assert_allow 'tar -tf /nix/store/abc-foo/x.tar'
              assert_allow 'rg pattern src/'
              assert_allow 'git log --find-renames'
              assert_allow 'du -sh /nix/var/nix/profiles'
              assert_allow 'ls /Users/josh/nix/store'
              assert_allow 'grep foo /home/x/nix/store'
              assert_allow 'ls /nixpkgs'
              assert_allow 'echo /nixos'
              assert_allow 'echo "see /nix/store for details"'
              assert_allow 'nix-store --gc --print-dead'
              assert_allow 'nix build .#foo && ls result/bin'
              assert_allow "find /nix/store/abc123-foo -name '*.so'"
              assert_allow "find . -name '*.nix'"
              assert_allow "rg -n 'nix/store' src/"

              assert_ignored "malformed json"  'not json at all{{{'
              assert_ignored "empty stdin"     ""
              assert_ignored "null tool_input" '{"tool_input":null}'
              assert_ignored "numeric command" '{"tool_input":{"command":42}}'
              assert_ignored "read payload"    '{"tool_name":"Read","tool_input":{"file_path":"/nix/store"}}'

              reason=$(jq --null-input --arg c "find /nix/store" '{tool_input:{command:$c}}' |
                claude-deny-nix-store-scan |
                jq --raw-output '.hookSpecificOutput | select(.hookEventName == "PreToolUse") | .permissionDecisionReason')
              if [ -z "$reason" ]; then
                echo "FAIL deny payload shape" >&2
                fail=1
              fi

              if [ "$fail" -ne 0 ]; then
                exit 1
              fi
              echo "ok: 48 commands, 5 payloads"

              touch $out
            '';
      };
  }
)
