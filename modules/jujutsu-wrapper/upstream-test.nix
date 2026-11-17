{ lib, pkgs }:
let
  gh = pkgs.writeShellScriptBin "gh" ''
    test "$#" -eq 7 && test "$1" = repo && test "$2" = view &&
      test "$4" = --json && test "$6" = --jq || exit 1
    test "$JJ_CONFIG" = "$EXPECTED_JJ_CONFIG" || exit 1
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
  customGit = pkgs.wlibEvalPackage [
    ../git-wrapper.nix
    { settings.url."file:///".insteadOf = "https://github.com/upstream/"; }
  ];
  customJj = pkgs.wlibEvalPackage [
    ../jujutsu-wrapper.nix
    {
      pkgs = lib.mkForce (
        pkgs
        // {
          nixbits = pkgs.nixbits // {
            jujutsu-git-set-upstream = pkgs.nixbits.jujutsu-git-set-upstream.override {
              nixbits = pkgs.nixbits // {
                inherit gh;
              };
            };
          };
        }
      );
      gitWrapper = customGit;
    }
  ];
  inheritedConfig = pkgs.writeText "jj-upstream-module-inherited.toml" ''
    [user]
    name = "Inherited Author"
    email = "inherited@example.com"
    [snapshot]
    auto-track = "glob:tracked*"
  '';
in
pkgs.runCommand "test-jj-upstream-module-propagation"
  {
    nativeBuildInputs = [
      pkgs.git
      pkgs.jujutsu
    ];
  }
  ''
    export HOME="$PWD/home" JJ_CONFIG=${inheritedConfig} EXPECTED_JJ_CONFIG=${inheritedConfig}
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
    ${customJj}/bin/jj-git-set-upstream

    test "$(cat "$GH_STUB_CALLS")" = "$(printf 'isFork\nparent\ndefaultBranchRef')"
    test "$(jj git remote list --ignore-working-copy | grep '^upstream ')" = "upstream $TEST_UPSTREAM_URL"
    test "$(jj config get 'revset-aliases."trunk()"')" = "main@upstream"
    test "$(jj log --ignore-working-copy --no-graph --revisions main@upstream --template 'commit_id')" = "$upstream"
    test "$(jj file list --ignore-working-copy)" = "tracked.txt"
    touch $out
  ''
