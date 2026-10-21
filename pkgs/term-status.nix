{
  lib,
  writeShellApplication,
  runCommand,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "term-status";
  runtimeInputs = [ coreutils ];
  text = builtins.readFile ./term-status.bash;
  passthru.tests = {
    outside-rex = runCommand "test-term-status-outside-rex" { } ''
      export TERM_STATUS_TTY="$PWD/tty"
      ${lib.getExe nixbits.term-status} done "Finished"
      status=0
      ${lib.getExe nixbits.term-status} -- sh -c 'exit 3' || status=$?
      if [ "$status" -ne 3 ]; then
        echo "expected exit status 3 but was $status"
        return 1
      fi
      if [ -s "$TERM_STATUS_TTY" ]; then
        echo "expected no reports outside Rex"
        return 1
      fi
      touch $out
    '';

    reports = runCommand "test-term-status-reports" { } ''
      export TERM_PROGRAM=rex TERM_STATUS_TTY="$PWD/tty"
      ${lib.getExe nixbits.term-status} --app nix-check -- true
      ${lib.getExe nixbits.term-status} --app nix-check -- false || true
      expected="$(printf '\e]7501;state=working:app=nix-check:msg=dHJ1ZQ==\e\\\e]7501;state=done:app=nix-check:msg=dHJ1ZQ==\e\\\e]7501;state=working:app=nix-check:msg=ZmFsc2U=\e\\\e]7501;state=error:app=nix-check:msg=ZmFsc2UgZmFpbGVkIChleGl0IDEp\e\\')"
      actual="$(cat "$TERM_STATUS_TTY")"
      if [ "$actual" != "$expected" ]; then
        echo "unexpected reports: $(printf '%q' "$actual")"
        return 1
      fi
      touch $out
    '';
  };
  meta = {
    description = "Report program status to the terminal with OSC 7501";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
