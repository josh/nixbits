{
  lib,
  writeShellApplication,
  runCommand,
  git,
  gnugrep,
}:
let
  git-track = writeShellApplication {
    name = "git-track";
    runtimeEnv = {
      PATH = lib.strings.makeBinPath [
        git
        gnugrep
      ];
    };
    # excludeShellChecks
    text = builtins.readFile ./git-track.bash;

    meta.description = "Set up tracking for current git branch";

    passthru.tests = {
      track =
        runCommand "test-git-track"
          {
            nativeBuildInputs = [
              git
              git-track
            ];
          }
          ''
            git init -b main
            git config user.email "you@example.com"
            git config user.name "Your Name"
            git commit --allow-empty --message "initial commit"

            git checkout -b foo
            git track

            touch $out
          '';

    };
  };
in
git-track
