{
  lib,
  writeShellApplication,
  runCommand,
  coreutils,
  nixbits,
}:
(writeShellApplication {
  name = "x-ln-store-entries";
  runtimeInputs = [
    coreutils
  ];
  inheritPath = false;
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./x-ln-store-entries.bash;
  meta = {
    description = "Conditionally link Nix store entries into a writable directory";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}).overrideAttrs
  (
    finalAttrs: _previousAttrs: {
      passthru.tests =
        let
          x-ln-store-entries = finalAttrs.finalPackage;
        in
        {
          links =
            runCommand "test-x-ln-store-entries-links"
              {
                nativeBuildInputs = [
                  coreutils
                  x-ln-store-entries
                ];
              }
              ''
                export NIX_STORE=$PWD/store
                mkdir -p store/src dst
                echo hello >store/src/file
                x-ln-store-entries store/src dst
                [ -L dst/file ]
                [ "$(readlink -f dst/file)" = "$(readlink -f store/src/file)" ]
                touch $out
              '';

          replaces-directory =
            runCommand "test-x-ln-store-entries-replaces-directory"
              {
                nativeBuildInputs = [
                  coreutils
                  x-ln-store-entries
                ];
              }
              ''
                export NIX_STORE=$PWD/store
                mkdir -p store/src dst/entry
                echo hello >store/src/entry
                echo stale >dst/entry/stale
                x-ln-store-entries store/src dst
                [ -L dst/entry ]
                [ "$(readlink -f dst/entry)" = "$(readlink -f store/src/entry)" ]
                touch $out
              '';

          replaces-symlinked-dst =
            runCommand "test-x-ln-store-entries-replaces-symlinked-dst"
              {
                nativeBuildInputs = [
                  coreutils
                  x-ln-store-entries
                ];
              }
              ''
                export NIX_STORE=$PWD/store
                mkdir -p store/old store/src
                echo hello >store/src/file
                ln -s "$PWD/store/old" dst
                x-ln-store-entries store/src dst
                [ ! -L dst ]
                [ -d dst ]
                [ -L dst/file ]
                [ ! -e store/old/file ]
                touch $out
              '';

          refuses-foreign-symlinked-dst =
            runCommand "test-x-ln-store-entries-refuses-foreign-symlinked-dst"
              {
                nativeBuildInputs = [
                  coreutils
                  x-ln-store-entries
                ];
              }
              ''
                export NIX_STORE=$PWD/store
                mkdir -p store/src other
                echo hello >store/src/file
                ln -s "$PWD/other" dst
                ! x-ln-store-entries store/src dst
                [ -L dst ]
                [ "$(readlink dst)" = "$PWD/other" ]
                [ ! -e other/file ]
                touch $out
              '';

          keeps-unmanaged =
            runCommand "test-x-ln-store-entries-keeps-unmanaged"
              {
                nativeBuildInputs = [
                  coreutils
                  x-ln-store-entries
                ];
              }
              ''
                export NIX_STORE=$PWD/store
                mkdir -p store/src dst/local-dir other
                echo hello >store/src/file
                echo local >dst/local-file
                ln -s "$PWD/other" dst/local-link
                x-ln-store-entries store/src dst
                [ -L dst/file ]
                [ -d dst/local-dir ] && [ ! -L dst/local-dir ]
                [ -f dst/local-file ] && [ ! -L dst/local-file ]
                [ -L dst/local-link ]
                touch $out
              '';

          prunes-stale =
            runCommand "test-x-ln-store-entries-prunes-stale"
              {
                nativeBuildInputs = [
                  coreutils
                  x-ln-store-entries
                ];
              }
              ''
                export NIX_STORE=$PWD/store
                mkdir -p store/old store/src dst
                echo hello >store/src/file
                echo stale >store/old/gone
                ln -s "$PWD/store/old/gone" dst/gone
                ln -s "$PWD/store/collected" dst/collected
                x-ln-store-entries store/src dst
                [ -L dst/file ]
                [ ! -L dst/gone ]
                [ ! -L dst/collected ]
                touch $out
              '';
        };
    }
  )
