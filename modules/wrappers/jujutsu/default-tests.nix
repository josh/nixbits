{ pkgs }:
let
  inherit (pkgs) runCommand testers;
  jujutsu = pkgs.wlibEvalPackage ../jujutsu.nix;
in
{
  config-override =
    let
      customConfig = pkgs.writeText "jj-override.toml" ''
        [user]
        name = "Override Author"
        email = "override@example.com"
      '';
      custom = pkgs.wlibEvalPackage [
        ../jujutsu.nix
        { configFile.path = customConfig; }
      ];
    in
    runCommand "test-jj-config-override" { } ''
      export HOME="$TMPDIR/home" JJ_CONFIG=/ignored/jj-config
      mkdir -p "$HOME"
      test "$(${custom}/bin/jj config get user.name)" = "Override Author"
      test "$(${custom}/bin/jj config get user.email)" = "override@example.com"
      touch "$out"
    '';

  version = testers.testVersion {
    package = jujutsu;
    command = "jj version";
    inherit (jujutsu) version;
  };

  author = runCommand "test-jj-author" { nativeBuildInputs = [ jujutsu ]; } ''
    expected="Joshua Peek"
    actual="$(jj config get user.name)"
    if [[ "$actual" != "$expected" ]]; then
      echo "expected, '$expected' but was '$actual'"
      return 1
    fi
    touch $out
  '';

  ignore = runCommand "test-jj-ignore" { nativeBuildInputs = [ jujutsu ]; } ''
    jj git init
    touch README.md
    mkdir .claude
    touch .claude/settings.local.json
    if ! jj file list | grep --quiet README.md; then
      echo "expected README.md to be tracked"
      return 1
    fi
    if jj file list | grep --quiet .claude/settings.local.json; then
      echo "expected .claude/settings.local.json to be ignored"
      return 1
    fi
    touch $out
  '';
}
