{
  lib,
  nixbits,
  runCommand,
  writeShellScriptBin,
  useModule,
}:
let
  credentials."https://git.example.com" = {
    helper = [
      ""
      "test-credential-helper"
    ];
    useHttpPath = true;
  };
  # Probe the environment at each application's real launch boundary.
  lazygitProbe =
    (writeShellScriptBin "lazygit" ''
      set -eu
      test "$GIT_CONFIG_GLOBAL" = "$EXPECTED_GIT_CONFIG"
      test "$(git config get --url=https://git.example.com/repo.git credential.helper)" = test-credential-helper
      test "$(git config get --url=https://git.example.com/repo.git credential.useHttpPath)" = true
      printf '%s\n' passed >"$PROBE_PASSED"
    '').overrideAttrs
      {
        pname = "lazygit";
        inherit (nixbits.lazygit) version meta;
      };
  lazyjjProbe =
    (writeShellScriptBin "lazyjj" ''
      set -eu
      test "$GIT_CONFIG_GLOBAL" = "$EXPECTED_GIT_CONFIG"
      test "$JJ_CONFIG" = "$EXPECTED_JJ_CONFIG"
      selectedGit="$(jj config get git.executable-path)"
      test "$selectedGit" = "$EXPECTED_GIT"
      test "$("$selectedGit" config get --url=https://git.example.com/repo.git credential.helper)" = test-credential-helper
      test "$("$selectedGit" config get --url=https://git.example.com/repo.git credential.useHttpPath)" = true
      printf '%s\n' passed >"$PROBE_PASSED"
    '').overrideAttrs
      {
        pname = "lazyjj";
        inherit (nixbits.lazyjj) version;
      };
  bundle = nixbits.vcs-dev-path.override (
    {
      nixbits = nixbits // {
        lazygit = nixbits.lazygit.override { lazygit = lazygitProbe; };
        lazyjj = nixbits.lazyjj.override { lazyjj = lazyjjProbe; };
      };
      gitModule = { lib, ... }: {
        settings = {
          user = {
            name = lib.mkForce "Module Author";
            email = lib.mkForce "module@example.com";
          };
          credential =
            if useModule then
              credentials
            else
              {
                "https://git.example.com" = {
                  helper = [
                    ""
                    "replaced-helper"
                  ];
                  username = "must-be-removed";
                };
              };
        };
      };
    }
    // lib.optionalAttrs (!useModule) { extraGitCredentials = credentials; }
  );
in
runCommand "test-vcs-dev-path-credential-propagation-${if useModule then "module" else "legacy"}"
  { }
  ''
    export HOME="$PWD/home" GIT_CONFIG_NOSYSTEM=1
    mkdir -p "$HOME"
    export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
    export EXPECTED_GIT_CONFIG=${bundle.git.configuration.constructFiles.gitconfig.outPath}
    export EXPECTED_JJ_CONFIG=${bundle.jujutsu.configuration.configFile.path}
    export EXPECTED_GIT=${lib.getExe bundle.git}
    test "$(readlink -f ${bundle}/bin/git)" = "$EXPECTED_GIT"
    test "$(${bundle}/bin/git config get user.name)" = 'Module Author'
    test "$(${bundle}/bin/git config get --url=https://git.example.com/repo.git credential.helper)" = test-credential-helper
    test "$(${bundle}/bin/git config get --url=https://git.example.com/repo.git credential.useHttpPath)" = true
    if ${bundle}/bin/git config get credential.https://git.example.com.username; then
      echo "Replaced credential field survived" >&2
      exit 1
    else
      test "$?" -eq 1
    fi
    test "$(${bundle}/bin/jj config get user.name)" = 'Module Author'
    test "$(${bundle}/bin/jj config get user.email)" = module@example.com
    test "$(${bundle}/bin/jj config get git.executable-path)" = "$EXPECTED_GIT"
    for app in lazygit lazyjj; do
      export PROBE_PASSED="$PWD/$app-passed"
      ${bundle}/bin/"$app" >/dev/null
      test -f "$PROBE_PASSED"
    done
    touch "$out"
  ''
