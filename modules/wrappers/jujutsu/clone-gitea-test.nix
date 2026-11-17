{ pkgs }:
let
  gh = pkgs.writeShellScriptBin "gh" ''
    test "$*" = 'repo view example/repo --json isFork,repositoryTopics' || exit 1
    touch "$GH_STUB_CALLED"
    echo '{"isFork":false,"repositoryTopics":[]}'
  '';
  gt = pkgs.writeShellScriptBin "gt" ''
    test "$*" = 'api --no-input repos/example/repo' || exit 1
    touch "$GT_STUB_CALLED"
    case "$GITEA_MODE" in
    primary) printf '{"mirror":false,"clone_url":"%s"}\n' "$TEST_GITEA_URL" ;;
    mirror) printf '{"mirror":true,"clone_url":"%s"}\n' "$TEST_GITEA_URL" ;;
    unavailable) exit 1 ;;
    *) exit 1 ;;
    esac
  '';
  customGit = pkgs.wlibEvalPackage [
    ../git.nix
    {
      settings.url."file:///".insteadOf = "localtest:///";
      settings.url."./seed".insteadOf = "https://github.com/example/repo.git";
    }
  ];
  customJj = pkgs.wlibEvalPackage [
    ../jujutsu.nix
    ({ config, ... }: {
      commands.jj-clone = pkgs.nixbits.jujutsu-clone.override {
        git-config = config.env.GIT_CONFIG_GLOBAL.data;
        jujutsu-config = config.configFile.path;
        jujutsu-git-set-upstream = config.commands.jj-git-set-upstream;
        nixbits = pkgs.nixbits // {
          inherit gh;
        };
        enableGitea = true;
        gitea-cli = gt;
      };
      gitWrapper = customGit;
      settings.user = {
        name = "Gitea Author";
        email = "gitea@example.com";
      };
    })
  ];

in
pkgs.runCommand "test-jj-clone-gitea-module-propagation"
  {
    nativeBuildInputs = [
      pkgs.git
      pkgs.jujutsu
    ];
  }
  ''
    export HOME="$PWD/home"
    unset GIT_CONFIG_GLOBAL JJ_CONFIG GT
    mkdir -p "$HOME"
    git init --initial-branch=main seed
    git -C seed -c user.name=Seed -c user.email=seed@example.com commit --allow-empty -m seed
    seed=$(git -C seed rev-parse HEAD)
    export TEST_GITEA_URL="localtest://$PWD/seed"
    export GH_STUB_CALLED="$PWD/gh-called" GT_STUB_CALLED="$PWD/gt-called"
    for mode in primary mirror unavailable; do
      export GITEA_MODE="$mode"
      rm -f "$GH_STUB_CALLED" "$GT_STUB_CALLED"
      ${customJj}/bin/jj-clone example/repo "$mode"
      test -f "$GT_STUB_CALLED"
      if [[ "$mode" = primary ]]; then
        test ! -e "$GH_STUB_CALLED"
      else
        test -f "$GH_STUB_CALLED"
      fi
      test "$(jj -R "$mode" log --ignore-working-copy --no-graph -r '@-' -T commit_id)" = "$seed"
      test "$(jj -R "$mode" log --ignore-working-copy --no-graph -r @ -T 'author.name()')" = 'Gitea Author'
      test "$(jj -R "$mode" log --ignore-working-copy --no-graph -r @ -T 'author.email()')" = gitea@example.com
    done
    touch "$out"
  ''
