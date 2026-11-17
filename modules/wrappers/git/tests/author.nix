{
  git,
  runCommand,
}:
runCommand "test-git-author" { nativeBuildInputs = [ git ]; } ''
  test "$(git config get user.name)" = "Joshua Peek"
  test "$(git config get user.email)" = "josh@users.noreply.github.com"
  touch $out
''
