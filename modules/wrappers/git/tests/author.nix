{
  git,
  runCommand,
}:
runCommand "test-git-author" { nativeBuildInputs = [ git ]; } ''
  expected="Joshua Peek"
  actual="$(git config get user.name)"
  if [[ "$actual" != "$expected" ]]; then
    echo "expected, '$expected' but was '$actual'"
    return 1
  fi
  test "$(git config get user.email)" = "josh@users.noreply.github.com"
  touch $out
''
