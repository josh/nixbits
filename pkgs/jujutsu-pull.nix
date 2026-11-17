{
  lib,
  writeShellApplication,
  runCommand,
  writeText,
  git,
  jujutsu,
  nixbits,
  git-config ? nixbits.git-config,
  jujutsu-config ? nixbits.jujutsu-config,
}:
writeShellApplication {
  name = "jj-pull";
  runtimeInputs = [
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = git-config;
    JJ_CONFIG = jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-pull.bash;

  passthru.tests.config-overrides =
    let
      jj-pull = nixbits.jujutsu-pull.override {
        git-config = writeText "jj-pull-git-config" ''
          [core]
          excludesFile = ${writeText "jj-pull-gitignore" "ignored-by-override\n"}
        '';
        jujutsu-config = writeText "jj-pull-config.toml" ''
          [user]
          name = "Override Author"
          email = "override@example.com"
          [git]
          executable-path = "${lib.getExe git}"
          [revset-aliases]
          "trunk()" = "main@origin"
        '';
      };
    in
    runCommand "test-jj-pull-config-overrides"
      {
        nativeBuildInputs = [
          git
          jujutsu
          jj-pull
        ];
      }
      ''
        export HOME="$PWD/home"
        unset GIT_CONFIG_GLOBAL JJ_CONFIG
        mkdir -p "$HOME"
        git init --initial-branch=main seed
        git -C seed config user.name "Seed Author"
        git -C seed config user.email "seed@example.com"
        git -C seed commit --allow-empty --message initial
        jj --config user.name='Seed Author' --config user.email=seed@example.com git clone "$PWD/seed" work

        git -C seed commit --allow-empty --message upstream
        upstream=$(git -C seed rev-parse HEAD)
        cd work
        touch visible ignored-by-override
        jj-pull

        test "$(jj log --ignore-working-copy --no-graph --revisions '@-' --template 'commit_id')" = "$upstream"
        test "$(jj log --ignore-working-copy --no-graph --revisions @ --template 'committer.name()')" = "Override Author"
        test "$(jj log --ignore-working-copy --no-graph --revisions @ --template 'committer.email()')" = "override@example.com"
        test "$(jj file list --ignore-working-copy)" = "visible"
        touch $out
      '';

  meta = {
    description = "Pull jj git remote";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
