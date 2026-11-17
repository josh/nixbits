{
  jujutsu,
  runCommand,
  symlinkJoin,
  wlibEvalPackage,
  writeShellScriptBin,
}:
let
  customJj = symlinkJoin {
    name = "custom-jj";
    inherit (jujutsu) version meta;
    paths = [ jujutsu ];
    postBuild = ''touch "$out/custom-jj-marker"'';
  };
  watchman = (writeShellScriptBin "watchman" "echo custom-watchman").overrideAttrs {
    meta.available = true;
  };
  unavailable = watchman // {
    meta = watchman.meta // {
      available = false;
    };
  };
  module =
    selectedWatchman:
    wlibEvalPackage [
      ../jujutsu.nix
      {
        jujutsuPackage = customJj;
        watchmanPackage = selectedWatchman;
      }
    ];

in
runCommand "test-jj-package-overrides" { } ''
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
