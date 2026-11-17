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
  jujutsu-git-set-upstream ? nixbits.jujutsu-git-set-upstream.override { inherit git-config; },
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
    jujutsu-git-set-upstream
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

  meta = {
    description = "Clone a jj repository";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
