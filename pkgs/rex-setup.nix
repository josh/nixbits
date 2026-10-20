{
  lib,
  writeShellApplication,
  runCommand,
  nixbits,
}:
writeShellApplication {
  name = "rex-setup";
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
  };
  meta = {
    description = "Install Rex's terminfo entry, ssh guard and agent skills when Rex is present";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
