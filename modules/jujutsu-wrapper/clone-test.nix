{ pkgs }:
let
  inherit (pkgs)
    writeShellScriptBin
    runCommand
    git
    jujutsu
    nixbits
    ;
  ghStub = writeShellScriptBin "gh" ''
    test "$1" = repo && test "$2" = view && test "$4" = --json || exit 1
    test "$JJ_CONFIG" = "$EXPECTED_JJ_CONFIG" || exit 1
    case "$5" in
    isFork,repositoryTopics)
      test "$#" -eq 5 && test "$3" = "$TEST_FORK_URL" || exit 1
      printf '%s\n' '{"isFork":true,"repositoryTopics":[]}'
      ;;
    isFork)
      test "$3" = "$TEST_FORK_FILE_URL" || exit 1
      touch tracked.txt manual.txt
      echo true
      ;;
    parent)
      test "$3" = "$TEST_FORK_FILE_URL" || exit 1
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
    {
      settings.url."file:///".insteadOf = [
        "localtest:///"
        "https://github.com/upstream/"
      ];
    }
  ];
  forkClone = pkgs.wlibEvalPackage [
    ../jujutsu-wrapper.nix
    {
      commands.clone = nixbits.jujutsu-clone.override {
        nixbits = nixbits // {
          gh = ghStub;
          jujutsu-git-set-upstream = nixbits.jujutsu-git-set-upstream.override {
            nixbits = nixbits // {
              gh = ghStub;
            };
          };
        };
      };
      gitWrapper = customGit;
      settings.user = {
        name = "Override Author";
        email = "override@example.com";
      };
      settings.snapshot.auto-track = "glob:tracked*";
    }
  ];
  jjConfig = forkClone.configuration.configFile.path;
in
runCommand "test-jj-fork-clone-module-propagation"
  {
    nativeBuildInputs = [
      git
      jujutsu
    ];
  }
  ''
    export HOME="$PWD/home" EXPECTED_JJ_CONFIG=${jjConfig}
    unset GIT_CONFIG_GLOBAL JJ_CONFIG GT
    mkdir -p "$HOME"
    git init --initial-branch=main upstream
    git -C upstream config user.name "Seed Author"
    git -C upstream config user.email "seed@example.com"
    git -C upstream commit --allow-empty --message initial
    git clone --bare upstream fork
    forkCommit=$(git -C fork rev-parse HEAD)
    git -C upstream commit --allow-empty --message upstream
    upstreamCommit=$(git -C upstream rev-parse HEAD)
    export TEST_FORK_URL="localtest://$PWD/fork" TEST_FORK_FILE_URL="file://$PWD/fork"
    export TEST_UPSTREAM_URL="https://github.com/upstream$PWD/upstream" GH_STUB_CALLS="$PWD/gh-calls"
    ${forkClone}/bin/jj-clone "$TEST_FORK_URL" work

    test "$(cat "$GH_STUB_CALLS")" = "$(printf 'isFork,repositoryTopics\nisFork\nparent\ndefaultBranchRef')"
    cd work
    test "$(jj git remote list --ignore-working-copy | grep '^upstream ')" = "upstream $TEST_UPSTREAM_URL"
    test "$(jj config get 'revset-aliases."trunk()"')" = "main@upstream"
    test "$(jj log --ignore-working-copy --no-graph --revisions main@upstream --template 'commit_id')" = "$upstreamCommit"
    test "$(jj log --ignore-working-copy --no-graph --revisions '@-' --template 'commit_id')" = "$forkCommit"
    test "$(jj log --ignore-working-copy --no-graph --revisions @ --template 'author.name()')" = "Override Author"
    test "$(jj log --ignore-working-copy --no-graph --revisions @ --template 'author.email()')" = "override@example.com"
    test "$(jj file list --ignore-working-copy)" = "tracked.txt"
    touch "$out"
  ''
