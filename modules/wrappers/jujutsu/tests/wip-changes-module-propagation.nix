{
  lib,
  runCommand,
  wlibEvalPackage,
  writeText,
}:
let
  customGit = wlibEvalPackage [
    ../../git.nix
    {
      settings.core.excludesFile = lib.mkForce (writeText "jj-wip-module-ignore" "tracked-ignored.txt\n");
    }
  ];
  customJj = wlibEvalPackage [
    ../../jujutsu.nix
    {
      gitWrapper = customGit;
      settings.snapshot.auto-track = "glob:tracked*";
      settings.revset-aliases."trunk()" = "root()";
    }
  ];
in
runCommand "test-jj-wip-changes-module-propagation" { } ''
  export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1
  mkdir -p "$HOME" repo
  cd repo
  ${customJj}/bin/jj git init
  export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
  test -z "$(${customJj}/bin/jj-wip-changes)"
  touch manual.txt tracked-ignored.txt
  test -z "$(${customJj}/bin/jj-wip-changes)"
  touch tracked.txt
  expected="$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'change_id.short(8)')*"
  test "$(${customJj}/bin/jj-wip-changes)" = "$expected"
  test "$(${customJj}/bin/jj file list --ignore-working-copy)" = tracked.txt
  touch "$out"
''
