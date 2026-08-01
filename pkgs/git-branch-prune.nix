{
  lib,
  writeShellApplication,
  runCommand,
  git,
}:
let
  git-branch-prune = writeShellApplication {
    name = "git-branch-prune";
    runtimeInputs = [ git ];
    inheritPath = false;
    text = builtins.readFile ./git-branch-prune.bash;

    passthru.tests = {
      prune =
        runCommand "test-git-branch-prune"
          {
            nativeBuildInputs = [
              git
              git-branch-prune
            ];
          }
          ''
            git init -b main
            git config user.email "you@example.com"
            git config user.name "Your Name"

            touch foo
            git add foo
            git commit -m "foo"

            git checkout -b bar
            touch bar
            git add bar
            git commit -m "bar"

            git checkout main
            git merge bar

            git-branch-prune
            if git show-ref --verify --quiet refs/heads/bar; then
              echo "bar not deleted" >&2
              exit 1
            fi
            touch $out
          '';

      worktree =
        runCommand "test-git-branch-prune-worktree"
          {
            nativeBuildInputs = [
              git
              git-branch-prune
            ];
          }
          ''
            git init -b main repo
            cd repo
            git config user.email "you@example.com"
            git config user.name "Your Name"

            touch foo
            git add foo
            git commit -m "foo"

            git branch checked-out
            git branch merged
            git worktree add ../wt checked-out

            git-branch-prune
            git show-ref --verify --quiet refs/heads/checked-out
            if git show-ref --verify --quiet refs/heads/merged; then
              echo "merged not deleted" >&2
              exit 1
            fi
            touch $out
          '';

      detached =
        runCommand "test-git-branch-prune-detached"
          {
            nativeBuildInputs = [
              git
              git-branch-prune
            ];
          }
          ''
            git init -b main
            git config user.email "you@example.com"
            git config user.name "Your Name"

            touch foo
            git add foo
            git commit -m "foo"

            git branch merged
            git checkout --detach main

            git-branch-prune
            if git show-ref --verify --quiet refs/heads/merged; then
              echo "merged not deleted" >&2
              exit 1
            fi
            touch $out
          '';

      dotted =
        runCommand "test-git-branch-prune-dotted"
          {
            nativeBuildInputs = [
              git
              git-branch-prune
            ];
          }
          ''
            git init -b main
            git config user.email "you@example.com"
            git config user.name "Your Name"

            touch foo
            git add foo
            git commit -m "foo"

            git branch fixxbug
            git checkout -b fix.bug

            git-branch-prune
            git show-ref --verify --quiet refs/heads/fix.bug
            if git show-ref --verify --quiet refs/heads/fixxbug; then
              echo "fixxbug not deleted" >&2
              exit 1
            fi
            touch $out
          '';
    };

    meta = {
      description = "Clean up git branches that have been merged into main";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  };
in
git-branch-prune
