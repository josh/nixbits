{
  lib,
  writeShellApplication,
  writeShellScript,
  runCommand,
  jq,
  nixbits,
}:
let
  fakeRex = writeShellScript "rex" ''
    case "$*" in
    version) ;;
    "terminfo setup --dry-run"*)
      echo '{"entry":{"status":"already installed"},"guard":{"status":"already current"}}'
      ;;
    "skill setup --dry-run"*)
      echo '{"steps":[{"change":"unchanged"},{"change":"skipped"}]}'
      ;;
    *)
      echo "$*" >>"$HOME/calls"
      ;;
    esac
  '';
in
writeShellApplication {
  name = "rex-setup";
  runtimeInputs = [ jq ];
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./rex-setup.bash;
  passthru.tests = {
    without-rex = runCommand "test-rex-setup-without-rex" { } ''
      export HOME="$PWD/home"
      mkdir "$HOME"
      PATH=/var/empty ${lib.getExe nixbits.rex-setup}
      if [ -n "$(ls -A "$HOME")" ]; then
        echo "expected HOME to stay empty"
        return 1
      fi
      touch $out
    '';

    already-set-up = runCommand "test-rex-setup-already-set-up" { } ''
      export HOME="$PWD/home"
      mkdir -p "$HOME" bin
      ln -s ${fakeRex} bin/rex
      output="$(PATH="$PWD/bin" ${lib.getExe nixbits.rex-setup} 2>&1)"
      if [ -n "$output" ] || [ -e "$HOME/calls" ]; then
        echo "expected a silent no-op but got '$output'"
        return 1
      fi
      touch $out
    '';
  };
  meta = {
    description = "Install Rex's terminfo entry, ssh guard and agent skills when Rex is present";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
