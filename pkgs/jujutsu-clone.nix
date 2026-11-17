{
  lib,
  writeShellApplication,
  writeShellScriptBin,
  runCommand,
  writeText,
  coreutils,
  git,
  jq,
  jujutsu,
  nur,
  nixbits,
  git-config ? nixbits.git-config,
  jujutsu-config ? nixbits.jujutsu-config,
  gitea-cli ? nur.repos.josh.gitea-cli,
  enableGitea ? false,
}:
let
  inherit (nixbits) gh;
in
writeShellApplication {
  name = "jj-clone";
  runtimeInputs = [
    coreutils
    gh
    git
    jq
    jujutsu
    (nixbits.jujutsu-git-set-upstream.override { inherit git-config; })
  ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = git-config;
    JJ_CONFIG = jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  }
  // lib.attrsets.optionalAttrs enableGitea {
    GT = lib.getExe gitea-cli;
  };
  text = builtins.readFile ./jujutsu-clone.bash;

  passthru.tests.config-overrides =
    let
      jj-clone = nixbits.jujutsu-clone.override {
        nixbits = nixbits // {
          gh = writeShellScriptBin "gh" ''
            test "$#" -eq 5 && test "$1" = repo && test "$2" = view &&
              test "$3" = "$TEST_REPO_URL" && test "$4" = --json &&
              test "$5" = isFork,repositoryTopics || exit 1
            touch "$GH_STUB_CALLED"
            printf '%s\n' '{"isFork":false,"repositoryTopics":[]}'
          '';
        };
        git-config = writeText "jj-clone-git-config" ''
          [url "file:///"]
          insteadOf = localtest:///
        '';
        jujutsu-config = writeText "jj-clone-config.toml" ''
          [user]
          name = "Override Author"
          email = "override@example.com"
          [git]
          executable-path = "${lib.getExe git}"
        '';
      };
    in
    runCommand "test-jj-clone-config-overrides"
      {
        nativeBuildInputs = [
          git
          jujutsu
          jj-clone
        ];
      }
      ''
        export HOME="$PWD/home"
        unset GIT_CONFIG_GLOBAL JJ_CONFIG GT
        mkdir -p "$HOME"
        git init --initial-branch=main seed
        git -C seed config user.name "Seed Author"
        git -C seed config user.email "seed@example.com"
        git -C seed commit --allow-empty --message initial
        upstream=$(git -C seed rev-parse HEAD)
        export TEST_REPO_URL="localtest://$PWD/seed" GH_STUB_CALLED="$PWD/gh-called"
        jj-clone "$TEST_REPO_URL" work

        test -f "$GH_STUB_CALLED"
        cd work
        test "$(jj log --ignore-working-copy --no-graph --revisions '@-' --template 'commit_id')" = "$upstream"
        test "$(jj log --ignore-working-copy --no-graph --revisions @ --template 'author.name()')" = "Override Author"
        test "$(jj log --ignore-working-copy --no-graph --revisions @ --template 'author.email()')" = "override@example.com"
        touch $out
      '';

  passthru.tests.fork-config-propagation =
    let
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
      jjConfig = writeText "jj-fork-clone-config.toml" ''
        [user]
        name = "Override Author"
        email = "override@example.com"
        [git]
        executable-path = "${lib.getExe git}"
        [snapshot]
        auto-track = "glob:tracked*"
      '';
      forkClone = nixbits.jujutsu-clone.override {
        nixbits = nixbits // {
          gh = ghStub;
          jujutsu-git-set-upstream = nixbits.jujutsu-git-set-upstream.override {
            nixbits = nixbits // {
              gh = ghStub;
            };
          };
        };
        git-config = writeText "jj-fork-clone-git-config" ''
          [url "file:///"]
          insteadOf = localtest:///
          insteadOf = https://github.com/upstream/
        '';
        jujutsu-config = jjConfig;
      };
    in
    runCommand "test-jj-fork-clone-config-propagation"
      {
        nativeBuildInputs = [
          git
          jujutsu
          forkClone
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
        jj-clone "$TEST_FORK_URL" work

        test "$(cat "$GH_STUB_CALLS")" = "$(printf 'isFork,repositoryTopics\nisFork\nparent\ndefaultBranchRef')"
        cd work
        test "$(jj git remote list --ignore-working-copy | grep '^upstream ')" = "upstream $TEST_UPSTREAM_URL"
        test "$(jj config get 'revset-aliases."trunk()"')" = "main@upstream"
        test "$(jj log --ignore-working-copy --no-graph --revisions main@upstream --template 'commit_id')" = "$upstreamCommit"
        test "$(jj log --ignore-working-copy --no-graph --revisions '@-' --template 'commit_id')" = "$forkCommit"
        test "$(jj log --ignore-working-copy --no-graph --revisions @ --template 'author.name()')" = "Override Author"
        test "$(jj log --ignore-working-copy --no-graph --revisions @ --template 'author.email()')" = "override@example.com"
        test "$(jj file list --ignore-working-copy)" = "tracked.txt"
        touch $out
      '';

  meta = {
    description = "Clone a jj repository";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
