{
  git,
  runCommand,
}:
runCommand "test-git-ignore" { nativeBuildInputs = [ git ]; } ''
  git init
  touch README.md
  mkdir .claude
  touch .claude/settings.local.json
  if git check-ignore README.md; then
    echo "expected README.md to not be ignored"
    return 1
  fi
  if ! git check-ignore .claude/settings.local.json; then
    echo "expected .claude/settings.local.json to be ignored"
    return 1
  fi
  touch $out
''
