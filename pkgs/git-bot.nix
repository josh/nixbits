{
  symlinkJoin,
  makeWrapper,
  runCommand,
  git,
  gnugrep,
  nixbits,
  testers,
}:
let
  git' = symlinkJoin {
    pname = "git-bot";
    inherit (git) version;
    paths = [ git ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/git \
        --set GIT_CONFIG_GLOBAL ${nixbits.git-bot-config}
    '';

    meta = {
      inherit (git.meta)
        description
        homepage
        platforms
        ;
      mainProgram = "git";
    };
  };
in
git'.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        git = finalAttrs.finalPackage;
      in
      {
        version = testers.testVersion {
          package = git;
          command = "git version";
          inherit (git) version;
        };

        user = runCommand "test-git-user" { nativeBuildInputs = [ git ]; } ''
          expected="github-actions[bot]"
          actual="$(git config get user.name)"
          if [[ "$actual" != "$expected" ]]; then
            echo "expected, '$expected' but was '$actual'"
            return 1
          fi
          touch $out
        '';

        commit-author =
          runCommand "test-git-commit-author"
            {
              nativeBuildInputs = [
                git
                gnugrep
              ];
            }
            ''
              git init --initial-branch main
              git commit --allow-empty --message "initial commit"
              git show HEAD | grep 'Author: github-actions\[bot\]'
              touch $out
            '';
      };
  }
)
