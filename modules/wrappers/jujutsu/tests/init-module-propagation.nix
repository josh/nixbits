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
        name = lib.mkForce "Module Author";
        email = lib.mkForce "git@example.com";
      };
      settings.core.excludesFile = lib.mkForce (writeText "jj-module-gitignore" "ignored-by-module\n");
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
runCommand "test-jj-init-module-propagation" { nativeBuildInputs = [ git ]; } ''
  export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1
  mkdir -p "$HOME" repo
  cd repo
  git init
  touch visible ignored-by-module
  export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
  ${customJj}/bin/jj-init
  test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'author.name()')" = "Module Author"
  test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'author.email()')" = jj@example.com
  test "$(${customJj}/bin/jj file list --ignore-working-copy)" = visible
  touch "$out"
''
