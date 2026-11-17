{
  lib,
  writeShellApplication,
  writeShellScriptBin,
  runCommand,
  writeText,
  coreutils,
  git,
  gnugrep,
  jujutsu,
  nixbits,
  git-config ? nixbits.git-config,
}:
let
  inherit (nixbits) gh;
in
writeShellApplication {
  name = "jj-git-set-upstream";
  runtimeInputs = [
    coreutils
    gh
    git
    gnugrep
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = git-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-git-set-upstream.bash;

  passthru.tests.git-config-override =
    let
      helper = nixbits.jujutsu-git-set-upstream.override {
        nixbits = nixbits // {
          gh = writeShellScriptBin "gh" ''
            test "$#" -eq 7 && test "$1" = repo && test "$2" = view &&
              test "$4" = --json && test "$6" = --jq || exit 1
            case "$5" in
            isFork)
              test "$3" = "$TEST_ORIGIN_URL" || exit 1
              echo true
              ;;
            parent)
              test "$3" = "$TEST_ORIGIN_URL" || exit 1
              echo "$TEST_UPSTREAM_URL"
              ;;
            defaultBranchRef)
              test "$3" = "$TEST_UPSTREAM_URL" || exit 1
              echo main
              ;;
            *) exit 1 ;;
            esac
            echo "$5" >>"$GH_STUB_CALLS"
          '';
        };
        git-config = writeText "jj-upstream-git-config" ''
          [url "file:///"]
          insteadOf = https://github.com/upstream/
        '';
      };
      inheritedConfig = writeText "jj-upstream-inherited.toml" ''
        [user]
        name = "Inherited Author"
        email = "inherited@example.com"
        [snapshot]
        auto-track = "glob:tracked*"
      '';
    in
    runCommand "test-jj-upstream-git-config-override"
      {
        nativeBuildInputs = [
          git
          jujutsu
          helper
        ];
      }
      ''
        export HOME="$PWD/home" JJ_CONFIG=${inheritedConfig}
        unset GIT_CONFIG_GLOBAL
        mkdir -p "$HOME"
        git init --initial-branch=main seed
        git -C seed config user.name "Seed Author"
        git -C seed config user.email "seed@example.com"
        git -C seed commit --allow-empty --message initial
        jj git clone "$PWD/seed" work
        git -C seed commit --allow-empty --message upstream
        upstream=$(git -C seed rev-parse HEAD)
        export TEST_ORIGIN_URL=https://github.com/example/fork.git
        export TEST_UPSTREAM_URL="https://github.com/upstream$PWD/seed" GH_STUB_CALLS="$PWD/gh-calls"
        cd work
        jj git remote set-url origin "$TEST_ORIGIN_URL"
        touch tracked.txt manual.txt
        jj-git-set-upstream

        test "$(cat "$GH_STUB_CALLS")" = "$(printf 'isFork\nparent\ndefaultBranchRef')"
        test "$(jj git remote list --ignore-working-copy | grep '^upstream ')" = "upstream $TEST_UPSTREAM_URL"
        test "$(jj config get 'revset-aliases."trunk()"')" = "main@upstream"
        test "$(jj log --ignore-working-copy --no-graph --revisions main@upstream --template 'commit_id')" = "$upstream"
        test "$(jj file list --ignore-working-copy)" = "tracked.txt"
        touch $out
      '';

  meta = {
    description = "Automatically configure jj git upstream remote";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
