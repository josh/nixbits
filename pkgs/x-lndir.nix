{
  lib,
  writeShellApplication,
  runCommand,
  coreutils,
  nixbits,
}:
(writeShellApplication {
  name = "x-lndir";
  runtimeInputs = [
    coreutils
  ];
  inheritPath = false;
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./x-lndir.bash;
  meta = {
    description = "Conditionally update directory of symlinks";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}).overrideAttrs
  (
    finalAttrs: _previousAttrs: {
      passthru.tests =
        let
          x-lndir = finalAttrs.finalPackage;
        in
        {
          links =
            runCommand "test-x-lndir-links"
              {
                nativeBuildInputs = [
                  coreutils
                  x-lndir
                ];
              }
              ''
                mkdir -p src dst
                echo hello >src/file
                x-lndir src dst
                [ -L dst/file ]
                [ "$(readlink -f dst/file)" = "$(readlink -f src/file)" ]
                touch $out
              '';

          replaces-directory =
            runCommand "test-x-lndir-replaces-directory"
              {
                nativeBuildInputs = [
                  coreutils
                  x-lndir
                ];
              }
              ''
                mkdir -p src dst/entry
                echo hello >src/entry
                echo stale >dst/entry/stale
                x-lndir src dst
                [ -L dst/entry ]
                [ "$(readlink -f dst/entry)" = "$(readlink -f src/entry)" ]
                touch $out
              '';

          prunes-stale =
            runCommand "test-x-lndir-prunes-stale"
              {
                nativeBuildInputs = [
                  coreutils
                  x-lndir
                ];
              }
              ''
                mkdir -p src dst
                echo hello >src/file
                ln -s /nonexistent dst/stale-link
                echo stale >dst/stale-file
                x-lndir src dst
                [ -L dst/file ]
                [ ! -e dst/stale-file ]
                [ ! -L dst/stale-link ]
                touch $out
              '';
        };
    }
  )
