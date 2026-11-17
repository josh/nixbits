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
  name = "jj-new-main";
  runtimeInputs = [
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = git-config;
    JJ_CONFIG = jujutsu-config;
  };
  text = builtins.readFile ./jujutsu-new-main.bash;

  passthru.tests.config-overrides =
    let
      jj-new-main = nixbits.jujutsu-new-main.override {
        git-config = writeText "jj-new-main-git-config" ''
          [core]
          excludesFile = ${writeText "jj-new-main-gitignore" "ignored-by-override\n"}
        '';
        jujutsu-config = writeText "jj-new-main-config.toml" ''
          [user]
          name = "Override Author"
          email = "override@example.com"
          [git]
          executable-path = "${lib.getExe git}"
        '';
      };
    in
    runCommand "test-jj-new-main-config-overrides"
      {
        nativeBuildInputs = [
          git
          jujutsu
          jj-new-main
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
        previous=$(jj log --ignore-working-copy --no-graph --revisions @ --template 'change_id')
        touch visible ignored-by-override
        jj-new-main

        test "$(jj log --ignore-working-copy --no-graph --revisions '@-' --template 'commit_id')" = "$upstream"
        test "$(jj log --ignore-working-copy --no-graph --revisions @ --template 'change_id')" != "$previous"
        test "$(jj log --ignore-working-copy --no-graph --revisions @ --template 'author.name()')" = "Override Author"
        test "$(jj log --ignore-working-copy --no-graph --revisions @ --template 'author.email()')" = "override@example.com"
        test "$(jj file list --ignore-working-copy --revision "$previous")" = "visible"
        touch $out
      '';

  meta = {
    description = "Fetch origin then create new change from main@origin";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
