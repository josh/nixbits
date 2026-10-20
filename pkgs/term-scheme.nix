{
  lib,
  writeShellApplication,
  runCommand,
  nixbits,
}:
writeShellApplication {
  name = "term-scheme";
  text = builtins.readFile ./term-scheme.bash;
  passthru.tests = {
    no-tty = runCommand "test-term-scheme-no-tty" { } ''
      if output="$(${lib.getExe nixbits.term-scheme} </dev/null)"; then
        echo "expected failure without a tty but printed '$output'"
        return 1
      fi
      if [ -n "$output" ]; then
        echo "expected no output but was '$output'"
        return 1
      fi
      touch $out
    '';
  };
  meta = {
    description = "Print whether the terminal's color scheme is dark or light";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
