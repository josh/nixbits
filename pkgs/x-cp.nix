{
  lib,
  writeShellApplication,
  runCommand,
  coreutils,
  diffutils,
  nixbits,
}:
(writeShellApplication {
  name = "x-cp";
  runtimeInputs = [
    coreutils
    diffutils
  ];
  inheritPath = false;
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./x-cp.bash;
  meta = {
    description = "Conditionally copy files";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}).overrideAttrs
  (
    finalAttrs: _previousAttrs: {
      passthru.tests =
        let
          x-cp = finalAttrs.finalPackage;
          runTest =
            name: script:
            runCommand "test-x-cp-${name}" {
              nativeBuildInputs = [
                coreutils
                x-cp
              ];
            } (script + "\ntouch $out\n");
        in
        {
          copies = runTest "copies" ''
            echo hello >src
            x-cp src dst
            [ "$(cat dst)" = "hello" ]
          '';

          creates-parent-dir = runTest "creates-parent-dir" ''
            echo hello >src
            x-cp src nested/dir/dst
            [ "$(cat nested/dir/dst)" = "hello" ]
          '';

          overwrites = runTest "overwrites" ''
            echo old >dst
            echo new >src
            x-cp src dst
            [ "$(cat dst)" = "new" ]
          '';

          overwrites-read-only = runTest "overwrites-read-only" ''
            echo old >dst
            echo new >src
            chmod a-w dst
            x-cp src dst
            [ "$(cat dst)" = "new" ]
          '';

          identical-is-noop = runTest "identical-is-noop" ''
            echo hello >src
            echo hello >dst
            chmod a-w dst
            x-cp src dst
            [ "$(cat dst)" = "hello" ]
          '';

          dry-run-does-not-write = runTest "dry-run-does-not-write" ''
            echo hello >src
            x-cp --dry-run src dst
            [ ! -e dst ]
          '';
        };
    }
  )
