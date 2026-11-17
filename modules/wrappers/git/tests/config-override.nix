{
  runCommand,
  wlibEvalPackage,
  writeText,
}:
let
  customConfig = writeText "custom-git-config" ''
    [user]
      name = Custom Git User
      email = custom@example.com
    [credential "https://git.example.com"]
        helper =
        helper = custom-helper
  '';
  custom = wlibEvalPackage [
    ../../git.nix
    { configFile.path = customConfig; }
  ];
in
runCommand "test-git-config-override" { } ''
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/ignored/git-config
  test "$(${custom}/bin/git config get user.name)" = "Custom Git User"
  test "$(${custom}/bin/git config get user.email)" = custom@example.com
  test "$(${custom}/bin/git config get --url=https://git.example.com credential.helper)" = custom-helper
  test "$(${custom}/bin/git config get --show-origin user.name)" = "$(printf 'file:%s\t%s' ${customConfig} 'Custom Git User')"
  touch "$out"
''
