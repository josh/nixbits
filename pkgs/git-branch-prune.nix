{
  lib,
  writeShellApplication,
  runCommand,
  git,
  gnugrep,
}:
let
  git-branch-prune = writeShellApplication {
    name = "git-branch-prune";
    runtimeEnv = {
      PATH = lib.strings.makeBinPath [
        git
        gnugrep
      ];
    };
    text = builtins.readFile ./git-branch-prune.bash;

    meta.description = "Clean up git branches that have been merged into main";

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
            if git branch -a | grep bar; then
              echo "bar not deleted" >&2
              exit 1
            fi
            touch $out
          '';
    };
  };
in
git-branch-prune
