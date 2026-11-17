{ pkgs }:
let
  customJj = pkgs.symlinkJoin {
    name = "custom-jj";
    inherit (pkgs.jujutsu) version meta;
    paths = [ pkgs.jujutsu ];
    postBuild = ''touch "$out/custom-jj-marker"'';
  };
  watchman = (pkgs.writeShellScriptBin "watchman" "echo custom-watchman").overrideAttrs {
    meta.available = true;
  };
  unavailable = watchman // {
    meta = watchman.meta // {
      available = false;
    };
  };
  module =
    selectedWatchman:
    pkgs.wlibEvalPackage [
      ../jujutsu-wrapper.nix
      {
        jujutsuPackage = customJj;
        watchmanPackage = selectedWatchman;
      }
    ];
  adapter =
    selectedWatchman:
    pkgs.nixbits.jujutsu.override {
      jujutsu = customJj;
      watchman = selectedWatchman;
    };
in
pkgs.runCommand "test-jj-package-overrides" { } ''
  for bundle in ${module watchman} ${adapter watchman}; do
    test -e "$bundle/custom-jj-marker"
    test "$("$bundle/bin/watchman")" = custom-watchman
    "$bundle/bin/jj" version
  done
  for bundle in ${module unavailable} ${adapter unavailable}; do
    test -e "$bundle/custom-jj-marker"
    test ! -e "$bundle/bin/watchman"
    "$bundle/bin/jj" version
  done
  touch "$out"
''
