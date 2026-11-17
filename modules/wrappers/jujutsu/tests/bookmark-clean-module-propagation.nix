{
  jujutsu,
  lib,
  runCommand,
  wlibEvalPackage,
  writeText,
}:
let
  customGit = wlibEvalPackage [
    ../../git.nix
    {
      settings.core.excludesFile = lib.mkForce (
        writeText "jj-bookmark-module-ignore" "ignored-by-module\n"
      );
    }
  ];
  customJj = wlibEvalPackage [
    ../../jujutsu.nix
    {
      gitWrapper = customGit;
      settings.revset-aliases."trunk()" = "@-";
    }
  ];
in
runCommand "test-jj-bookmark-clean-module-propagation" { nativeBuildInputs = [ jujutsu ]; } ''
  export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1
  export JJ_CONFIG=${customJj.configuration.configFile.path}
  unset GIT_CONFIG_GLOBAL
  mkdir -p "$HOME" repo
  cd repo
  jj --config 'revset-aliases."trunk()"="root()"' git init
  jj describe -m base
  jj bookmark create main master
  jj new
  jj describe -m merged
  jj bookmark create push-merged
  jj new
  jj bookmark create push-unmerged
  touch visible ignored-by-module
  export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
  ${customJj}/bin/jj-bookmark-clean
  expected=$(printf 'main\nmaster\npush-unmerged')
  test "$(${customJj}/bin/jj bookmark list --ignore-working-copy -T 'name ++ "\n"')" = "$expected"
  test "$(${customJj}/bin/jj file list --ignore-working-copy)" = visible
  touch "$out"
''
