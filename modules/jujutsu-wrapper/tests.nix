{ lib, pkgs }:
let
  mkUntrackedTest =
    name: initArgs:
    let
      customGit = pkgs.wlibEvalPackage [
        ../git-wrapper.nix
        {
          settings.core.excludesFile = lib.mkForce (
            pkgs.writeText "jj-untracked-module-gitignore" "tracked-ignored.txt\n"
          );
        }
      ];
      customJj = pkgs.wlibEvalPackage [
        ../jujutsu-wrapper.nix
        {
          gitWrapper = customGit;
          settings.snapshot.auto-track = "glob:tracked*";
        }
      ];
    in
    pkgs.runCommand "test-jj-untracked-${name}-module-propagation" { } ''
      export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1
      unset GIT_CONFIG_GLOBAL JJ_CONFIG
      mkdir -p "$HOME" repo
      cd repo
      ${customJj}/bin/jj git init ${initArgs}
      touch tracked.txt tracked-ignored.txt manual.txt
      export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
      actual="$(${customJj}/bin/jj-untracked)"
      expected=$(printf 'manual.txt\ntracked-ignored.txt')
      if [[ "$actual" != "$expected" ]]; then
        echo "expected '$expected' but was '$actual'" >&2
        exit 1
      fi
      test "$(${customJj}/bin/jj file list --ignore-working-copy)" = tracked.txt
      touch "$out"
    '';
in
{
  clone-module-propagation = import ./clone-test.nix { inherit lib pkgs; };
  clone-gitea-module-propagation = import ./clone-gitea-test.nix { inherit lib pkgs; };
  upstream-module-propagation = import ./upstream-test.nix { inherit lib pkgs; };

  bookmark-clean-module-propagation =
    let
      customGit = pkgs.wlibEvalPackage [
        ../git-wrapper.nix
        {
          settings.core.excludesFile = lib.mkForce (
            pkgs.writeText "jj-bookmark-module-ignore" "ignored-by-module\n"
          );
        }
      ];
      customJj = pkgs.wlibEvalPackage [
        ../jujutsu-wrapper.nix
        {
          gitWrapper = customGit;
          settings.revset-aliases."trunk()" = "@-";
        }
      ];
    in
    pkgs.runCommand "test-jj-bookmark-clean-module-propagation"
      { nativeBuildInputs = [ pkgs.jujutsu ]; }
      ''
        export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1
        export JJ_CONFIG=${customJj.configuration.configFile.path}
        unset GIT_CONFIG_GLOBAL
        mkdir -p "$HOME" repo
        cd repo
        jj --config 'revset-aliases."trunk()"="root()"' git init
        jj describe -m base
        jj bookmark create main master
        jj new
        jj describe -m merged
        jj bookmark create push-merged
        jj new
        jj bookmark create push-unmerged
        touch visible ignored-by-module
        export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
        ${customJj}/bin/jj-bookmark-clean
        expected=$(printf 'main\nmaster\npush-unmerged')
        test "$(${customJj}/bin/jj bookmark list --ignore-working-copy -T 'name ++ "\n"')" = "$expected"
        test "$(${customJj}/bin/jj file list --ignore-working-copy)" = visible
        touch "$out"
      '';

  wip-changes-module-propagation =
    let
      customGit = pkgs.wlibEvalPackage [
        ../git-wrapper.nix
        {
          settings.core.excludesFile = lib.mkForce (
            pkgs.writeText "jj-wip-module-ignore" "tracked-ignored.txt\n"
          );
        }
      ];
      customJj = pkgs.wlibEvalPackage [
        ../jujutsu-wrapper.nix
        {
          gitWrapper = customGit;
          settings.snapshot.auto-track = "glob:tracked*";
          settings.revset-aliases."trunk()" = "root()";
        }
      ];
    in
    pkgs.runCommand "test-jj-wip-changes-module-propagation" { } ''
      export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1
      mkdir -p "$HOME" repo
      cd repo
      ${customJj}/bin/jj git init
      export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
      test -z "$(${customJj}/bin/jj-wip-changes)"
      touch manual.txt tracked-ignored.txt
      test -z "$(${customJj}/bin/jj-wip-changes)"
      touch tracked.txt
      expected="$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'change_id.short(8)')*"
      test "$(${customJj}/bin/jj-wip-changes)" = "$expected"
      test "$(${customJj}/bin/jj file list --ignore-working-copy)" = tracked.txt
      touch "$out"
    '';

  untracked-colocated-module-propagation = mkUntrackedTest "colocated" "--colocate";
  untracked-non-colocated-module-propagation = mkUntrackedTest "non-colocated" "--no-colocate";

  init-module-propagation =
    let
      customGit = pkgs.wlibEvalPackage [
        ../git-wrapper.nix
        {
          settings.user = {
            name = lib.mkForce "Module Author";
            email = lib.mkForce "git@example.com";
          };
          settings.core.excludesFile = lib.mkForce (
            pkgs.writeText "jj-module-gitignore" "ignored-by-module\n"
          );
        }
      ];
      customJj = pkgs.wlibEvalPackage [
        ../jujutsu-wrapper.nix
        {
          gitWrapper = customGit;
          settings.user.email = "jj@example.com";
        }
      ];
    in
    pkgs.runCommand "test-jj-init-module-propagation" { nativeBuildInputs = [ pkgs.git ]; } ''
      export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1
      mkdir -p "$HOME" repo
      cd repo
      git init
      touch visible ignored-by-module
      export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
      ${customJj}/bin/jj-init
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'author.name()')" = "Module Author"
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'author.email()')" = jj@example.com
      test "$(${customJj}/bin/jj file list --ignore-working-copy)" = visible
      touch "$out"
    '';

  pull-module-propagation =
    let
      customGit = pkgs.wlibEvalPackage [
        ../git-wrapper.nix
        {
          settings.user = {
            name = lib.mkForce "Pull Author";
            email = lib.mkForce "git@example.com";
          };
          settings.core.excludesFile = lib.mkForce (
            pkgs.writeText "jj-pull-module-gitignore" "ignored-by-module\n"
          );
          # The selected Git wrapper may have behavior beyond setting its config.
          runShell = [ ''echo git >>"$GIT_EXECUTION_LOG"'' ];
        }
      ];
      customJj = pkgs.wlibEvalPackage [
        ../jujutsu-wrapper.nix
        {
          gitWrapper = customGit;
          settings.user.email = "jj@example.com";
        }
      ];
    in
    pkgs.runCommand "test-jj-pull-module-propagation" { nativeBuildInputs = [ pkgs.git ]; } ''
      export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1 GIT_EXECUTION_LOG="$TMPDIR/git-executions"
      unset GIT_CONFIG_GLOBAL JJ_CONFIG
      mkdir -p "$HOME"
      git init --initial-branch=main seed
      git -C seed config user.name "Seed Author"
      git -C seed config user.email seed@example.com
      git -C seed commit --allow-empty --message initial
      ${customJj}/bin/jj git clone "$PWD/seed" work
      git -C seed commit --allow-empty --message upstream
      upstream=$(git -C seed rev-parse HEAD)
      cd work
      touch visible ignored-by-module
      : >"$GIT_EXECUTION_LOG"
      export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
      ${customJj}/bin/jj-pull
      test -s "$GIT_EXECUTION_LOG"
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r '@-' -T commit_id)" = "$upstream"
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'committer.name()')" = "Pull Author"
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'committer.email()')" = jj@example.com
      test "$(${customJj}/bin/jj file list --ignore-working-copy)" = visible
      touch "$out"
    '';

  new-main-module-propagation =
    let
      customGit = pkgs.wlibEvalPackage [
        ../git-wrapper.nix
        {
          settings.user = {
            name = lib.mkForce "New Main Author";
            email = lib.mkForce "git@example.com";
          };
          settings.core.excludesFile = lib.mkForce (
            pkgs.writeText "jj-new-main-module-gitignore" "ignored-by-module\n"
          );
        }
      ];
      customJj = pkgs.wlibEvalPackage [
        ../jujutsu-wrapper.nix
        {
          gitWrapper = customGit;
          settings.user.email = "jj@example.com";
        }
      ];
    in
    pkgs.runCommand "test-jj-new-main-module-propagation" { nativeBuildInputs = [ pkgs.git ]; } ''
      export HOME="$TMPDIR/home" GIT_CONFIG_NOSYSTEM=1
      unset GIT_CONFIG_GLOBAL JJ_CONFIG
      mkdir -p "$HOME"
      git init --initial-branch=main seed
      git -C seed config user.name "Seed Author"
      git -C seed config user.email seed@example.com
      git -C seed commit --allow-empty --message initial
      ${customJj}/bin/jj git clone "$PWD/seed" work
      git -C seed commit --allow-empty --message upstream
      upstream=$(git -C seed rev-parse HEAD)
      cd work
      previous=$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T change_id)
      touch visible ignored-by-module
      export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
      ${customJj}/bin/jj-new-main
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r '@-' -T commit_id)" = "$upstream"
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'author.name()')" = "New Main Author"
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T 'author.email()')" = jj@example.com
      test "$(${customJj}/bin/jj log --ignore-working-copy --no-graph -r @ -T change_id)" != "$previous"
      test "$(${customJj}/bin/jj file list --ignore-working-copy --revision "$previous")" = visible
      touch "$out"
    '';
}
