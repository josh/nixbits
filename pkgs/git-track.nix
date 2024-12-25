{
  resholve,
  runCommand,
  bash,
  git,
}:
let
  git-track = resholve.writeScriptBin "git-track" {
    interpreter = "${bash}/bin/bash";
    inputs = [
      git
    ];
    execer = [
      "cannot:${git}/bin/git"
    ];
  } (builtins.readFile ./git-track.bash);
in
git-track
// {
  tests.track =
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
}
