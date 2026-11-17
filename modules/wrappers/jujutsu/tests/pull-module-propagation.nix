{
  git,
  lib,
  runCommand,
  wlibEvalPackage,
  writeText,
}:
let
  customGit = wlibEvalPackage [
    ../../git.nix
    {
      settings.user = {
        name = lib.mkForce "Pull Author";
        email = lib.mkForce "git@example.com";
      };
      settings.core.excludesFile = lib.mkForce (
        writeText "jj-pull-module-gitignore" "ignored-by-module\n"
      );
      # The selected Git wrapper may have behavior beyond setting its config.
      runShell = [ ''echo git >>"$GIT_EXECUTION_LOG"'' ];
    }
  ];
  customJj = wlibEvalPackage [
    ../../jujutsu.nix
    {
      gitWrapper = customGit;
      settings.user.email = "jj@example.com";
    }
  ];
in
runCommand "test-jj-pull-module-propagation" { nativeBuildInputs = [ git ]; } ''
  export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1 GIT_EXECUTION_LOG="$TMPDIR/git-executions"
  unset GIT_CONFIG_GLOBAL JJ_CONFIG
  mkdir -p "$HOME"
  git init --initial-branch=main seed
  git -C seed config user.name "Seed Author"
  git -C seed config user.email seed@example.com
  git -C seed commit --allow-empty --message initial
  ${customJj}/bin/jj git clone "$PWD/seed" work
  git -C seed commit --allow-empty --message upstream
  upstream=$(git -C seed rev-parse HEAD)
  cd work
  touch visible ignored-by-module
  : >"$GIT_EXECUTION_LOG"
  export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
  ${customJj}/bin/jj-pull
  test -s "$GIT_EXECUTION_LOG"
  test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r '@-' -T commit_id)" = "$upstream"
  test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'committer.name()')" = "Pull Author"
  test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'committer.email()')" = jj@example.com
  test "$(${customJj}/bin/jj file list --ignore-working-copy)" = visible
  touch "$out"
''
