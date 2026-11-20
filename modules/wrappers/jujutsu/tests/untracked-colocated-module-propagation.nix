{
  lib,
  runCommand,
  wlibEvalPackage,
  writeText,
  colocated ? true,
}:
let
  name = if colocated then "colocated" else "non-colocated";
  initArgs = if colocated then "--colocate" else "--no-colocate";
  customGit = wlibEvalPackage [
    ../../git.nix
    {
      settings.core.excludesFile = lib.mkForce (
        writeText "jj-untracked-module-gitignore" "tracked-ignored.txt\n"
      );
    }
  ];
  customJj = wlibEvalPackage [
    ../../jujutsu.nix
    {
      gitWrapper = customGit;
      settings.snapshot.auto-track = "glob:tracked*";
    }
  ];
in
runCommand "test-jj-untracked-${name}-module-propagation" { } ''
  export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1
  unset GIT_CONFIG_GLOBAL JJ_CONFIG
  mkdir -p "$HOME" repo
  cd repo
  ${customJj}/bin/jj git init ${initArgs}
  touch tracked.txt tracked-ignored.txt manual.txt
  export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
  actual="$(${customJj}/bin/jj-untracked)"
  expected=$(printf 'manual.txt\ntracked-ignored.txt')
  if [[ $actual != "$expected" ]]; then
    echo "expected '$expected' but was '$actual'" >&2
    exit 1
  fi
  test "$(${customJj}/bin/jj file list --ignore-working-copy)" = tracked.txt
  touch "$out"
''
