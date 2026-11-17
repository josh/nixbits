{
  runCommand,
  testers,
  wlibEvalPackage,
  writeText,
}:
let
  jujutsu = wlibEvalPackage ../jujutsu.nix;
in
{
  config-override =
    let
      customConfig = writeText "jj-override.toml" ''
        [user]
        name = "Override Author"
        email = "override@example.com"
      '';
      custom = wlibEvalPackage [
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
