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
        name = lib.mkForce "New Trunk Author";
        email = lib.mkForce "git@example.com";
      };
      settings.core.excludesFile = lib.mkForce (
        writeText "jj-new-trunk-module-gitignore" "ignored-by-module\n"
      );
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
runCommand "test-jj-new-trunk-module-propagation" { nativeBuildInputs = [ git ]; } ''
  export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1
  unset GIT_CONFIG_GLOBAL JJ_CONFIG
  mkdir -p "$HOME"
  git init --initial-branch=master seed
  git -C seed config user.name "Seed Author"
  git -C seed config user.email seed@example.com
  git -C seed commit --allow-empty --message initial
  ${customJj}/bin/jj git clone "$PWD/seed" work
  git -C seed commit --allow-empty --message upstream
  upstream=$(git -C seed rev-parse HEAD)
  cd work
  previous=$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T change_id)
  touch visible ignored-by-module
  export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
  ${customJj}/bin/jj-new-trunk
  test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r '@-' -T commit_id)" = "$upstream"
  test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'author.name()')" = "New Trunk Author"
  test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'author.email()')" = jj@example.com
  test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T change_id)" != "$previous"
  test "$(${customJj}/bin/jj file list --ignore-working-copy --revision "$previous")" = visible
  git -C ../seed commit --allow-empty --message deprecated
  deprecated=$(git -C ../seed rev-parse HEAD)
  ${customJj}/bin/jj-new-main 2>"$TMPDIR/stderr"
  grep --quiet "jj-new-main is deprecated" "$TMPDIR/stderr"
  test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r '@-' -T commit_id)" = "$deprecated"
  touch "$out"
''
