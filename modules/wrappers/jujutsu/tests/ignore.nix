{
  runCommand,
  wlibEvalPackage,
}:
let
  jujutsu = wlibEvalPackage ../../jujutsu.nix;
in
runCommand "test-jj-ignore" { nativeBuildInputs = [ jujutsu ]; } ''
  jj git init
  touch README.md
  mkdir .claude
  touch .claude/settings.local.json
  if ! jj file list | grep --quiet README.md; then
    echo "expected README.md to be tracked"
    return 1
  fi
  if jj file list | grep --quiet .claude/settings.local.json; then
    echo "expected .claude/settings.local.json to be ignored"
    return 1
  fi
  touch $out
''
