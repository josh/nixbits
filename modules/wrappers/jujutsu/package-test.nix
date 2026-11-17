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
      ../jujutsu.nix
      {
        jujutsuPackage = customJj;
        watchmanPackage = selectedWatchman;
      }
    ];

in
pkgs.runCommand "test-jj-package-overrides" { } ''
  bundle=${module watchman}
  test -e "$bundle/custom-jj-marker"
  test "$("$bundle/bin/watchman")" = custom-watchman
  "$bundle/bin/jj" version
  bundle=${module unavailable}
  test -e "$bundle/custom-jj-marker"
  test ! -e "$bundle/bin/watchman"
  "$bundle/bin/jj" version
  touch "$out"
''
