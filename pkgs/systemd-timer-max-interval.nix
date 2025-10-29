{
  python3,
  stdenvNoCC,
  runCommand,
  systemd,
}:
let
  python = python3.withPackages (ps: [
    ps.click
  ]);
in
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  name = "systemd-timer-max-interval";

  buildCommand = ''
    mkdir -p $out/bin
    (
      echo "#!${python.interpreter}"
      cat "${./systemd-timer-max-interval.py}"
    ) >$out/bin/systemd-timer-max-interval
    substituteInPlace $out/bin/systemd-timer-max-interval \
      --replace-fail "@systemd-analyze@" "${systemd}/bin/systemd-analyze"
    chmod +x $out/bin/systemd-timer-max-interval
  '';

  meta = {
    mainProgram = "systemd-timer-max-interval";
    description = "Calculate the maximum interval between systemd timer triggers";
    inherit (systemd.meta) platforms;
  };

  passthru.tests =
    let
      systemd-timer-max-interval = finalAttrs.finalPackage;
    in
    {
      help =
        runCommand "test-systemd-timer-max-interval-help"
          { nativeBuildInputs = [ systemd-timer-max-interval ]; }
          ''
            systemd-timer-max-interval --help
            touch $out
          '';

      timespan =
        runCommand "test-systemd-timer-max-interval-timespan"
          { nativeBuildInputs = [ systemd-timer-max-interval ]; }
          ''
            actual="$(systemd-timer-max-interval --timespan 1h)"
            expected="3600"
            if [ "$actual" != "$expected" ]; then
              echo "expected: '$expected' but was '$actual'"
              return 1
            fi
            touch $out
          '';

      calendar =
        runCommand "test-systemd-timer-max-interval-calendar"
          { nativeBuildInputs = [ systemd-timer-max-interval ]; }
          ''
            actual="$(systemd-timer-max-interval --calendar daily)"
            expected="86400"
            if [ "$actual" != "$expected" ]; then
              echo "expected: '$expected' but was '$actual'"
              return 1
            fi 
            touch $out
          '';

      timespan-randomized-delay =
        runCommand "test-systemd-timer-max-interval-timespan-randomized-delay"
          { nativeBuildInputs = [ systemd-timer-max-interval ]; }
          ''
            actual="$(systemd-timer-max-interval --timespan 1h --randomized-delay 5m)"
            expected="3900"
            if [ "$actual" != "$expected" ]; then
              echo "expected: '$expected' but was '$actual'"
              return 1
            fi
            touch $out
          '';
    };
})
