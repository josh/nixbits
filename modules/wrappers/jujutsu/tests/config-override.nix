{
  runCommand,
  wlibEvalPackage,
  writeText,
}:
let
  customConfig = writeText "jj-override.toml" ''
    [user]
    name = "Override Author"
    email = "override@example.com"
  '';
  custom = wlibEvalPackage [
    ../../jujutsu.nix
    { configFile.path = customConfig; }
  ];
in
runCommand "test-jj-config-override" { } ''
  export HOME="$TMPDIR/home" JJ_CONFIG=/ignored/jj-config
  mkdir -p "$HOME"
  test "$(${custom}/bin/jj config get user.name)" = "Override Author"
  test "$(${custom}/bin/jj config get user.email)" = "override@example.com"
  touch "$out"
''
