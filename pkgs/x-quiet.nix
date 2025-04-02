# TODO: Deprecate this
{
  lib,
  writeShellApplication,
  runCommand,
  nixbits,
}:
let
  x-quiet = writeShellApplication {
    name = "x-quiet";
    text = ''
      # shellcheck disable=SC1091
      source ${nixbits.xtrace}/share/bash/xtrace.bash
      [ "$1" == "--" ] && shift
      x-silent "$@"
    '';
    meta = {
      description = "Runs command, if succesful is silent, else log to stderr";
      platforms = lib.platforms.all;
    };
  };
in
x-quiet.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        x-quiet = finalAttrs.finalPackage;
      in
      {
        success =
          runCommand "test-x-quiet-success"
            {
              __structuredAttrs = true;
              nativeBuildInputs = [ x-quiet ];
            }
            ''
              x-quiet ls 2>err.txt
              if [ -s err.txt ]; then
                echo "expected stderr to be empty"
                exit 1
              fi
              touch $out
            '';

        failure =
          runCommand "test-x-quiet-failure"
            {
              __structuredAttrs = true;
              nativeBuildInputs = [ x-quiet ];
              env.expectedErr = "+ missing-command\n/nix/store/lhasjk6ib3kwx69w2yjh38rv36ws6khl-xtrace/share/bash/xtrace.bash: line 43: missing-command: command not found";
            }
            ''
              if x-quiet missing-command 2>err.txt; then
                echo "expected command to fail"
                exit 1
              fi
              actualErr=$(cat err.txt)
              if [ "$actualErr" != "$expectedErr" ]; then
                echo "expected stderr to be '$expectedErr', actual: '$actualErr'"
                exit 1
              fi
              touch $out
            '';

        failure-quoting =
          runCommand "test-x-quiet-failure-quoting"
            {
              __structuredAttrs = true;
              nativeBuildInputs = [ x-quiet ];
              env.expectedErr = "+ hello -m 'hello world'\n/nix/store/lhasjk6ib3kwx69w2yjh38rv36ws6khl-xtrace/share/bash/xtrace.bash: line 43: hello: command not found";
            }
            ''
              if x-quiet hello -m 'hello world' 2>err.txt; then
                echo "expected command to fail"
                exit 1
              fi
              actualErr=$(cat err.txt)
              if [ "$actualErr" != "$expectedErr" ]; then
                echo "expected stderr to be '$expectedErr', actual: '$actualErr'"
                exit 1
              fi
              touch $out
            '';
      };
  }
)
