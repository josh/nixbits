{
  git,
  runCommand,
}:
runCommand "test-git-bundled-helpers" { nativeBuildInputs = [ git ]; } ''
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  export GIT_CONFIG_NOSYSTEM=1
  unset GIT_CONFIG_GLOBAL
  test -x ${git}/bin/git-branch-prune
  test -x ${git}/bin/git-fetch-dir
  git init -b main repo
  git -C repo commit --allow-empty -m initial
  git init --bare remote.git
  git -C repo remote add origin "$PWD/remote.git"
  git -C repo push origin main
  git -C repo update-ref -d refs/remotes/origin/main
  git fetch-dir "$PWD/repo"
  test "$(git -C repo rev-parse origin/main)" = "$(git -C repo rev-parse main)"
  touch "$out"
''
