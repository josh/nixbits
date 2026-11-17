{
  lib,
  runCommand,
  wlibEvalPackage,
}:
let
  custom = wlibEvalPackage [
    ../../git.nix
    {
      settings.user.name = lib.mkForce "Module User";
      settings.credential."https://git.example.com".helper = [
        ""
        "module-helper"
      ];
    }
  ];
in
runCommand "test-git-wrapper-module-settings" { } ''
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  export GIT_CONFIG_NOSYSTEM=1
  unset GIT_CONFIG_GLOBAL
  test "$(${lib.getExe custom} config get user.name)" = "Module User"
  test "$(${lib.getExe custom} config get user.email)" = "josh@users.noreply.github.com"
  test "$(${lib.getExe custom} config get --url=https://git.example.com credential.helper)" = module-helper
  touch "$out"
''
