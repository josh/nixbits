{
  git,
  runCommand,
}:
runCommand "test-git-default-branch" { nativeBuildInputs = [ git ]; } ''
  git init
  if [[ "$(git branch --show-current)" != "main" ]]; then
    echo "expected, 'main' but was '$(git branch --show-current)'"
    return 1
  fi
  touch $out
''
