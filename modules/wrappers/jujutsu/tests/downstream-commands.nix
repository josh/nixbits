{
  runCommand,
  wlibEvalPackage,
  writeShellScriptBin,
}:
let
  review = writeShellScriptBin "review-work" ''
    set -eu
    test "$JJ_CONFIG" = caller-jj-config
    test "$GIT_CONFIG_GLOBAL" = caller-git-config
    printf '%s\n' "$@"
  '';
  customJj = wlibEvalPackage [
    ../../jujutsu.nix
    { commands.review-work = review; }
    {
      commands.jj-review = writeShellScriptBin "jj-review" ''
        echo custom-review
      '';
      commands.jj-init = writeShellScriptBin "jj-init" ''
        echo custom-init
      '';
    }
  ];
in
runCommand "test-jj-module-downstream-commands" { } ''
  export HOME="$PWD/home"
  mkdir -p "$HOME"
  export JJ_CONFIG=caller-jj-config GIT_CONFIG_GLOBAL=caller-git-config
  test "$(${customJj}/bin/review-work 'argument with spaces')" = 'argument with spaces'
  test "$(readlink ${customJj}/bin/review-work)" = ${review}/bin/review-work
  test "$(${customJj}/bin/jj-review)" = custom-review
  test "$(${customJj}/bin/jj-init)" = custom-init
  for command in jj jj-clone jj-pull jj-new-main jj-untracked jj-wip-changes jj-bookmark-clean jj-git-set-upstream; do
    test -x "${customJj}/bin/$command"
  done
  touch "$out"
''
