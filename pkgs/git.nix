{
  symlinkJoin,
  makeWrapper,
  runCommand,
  git,
  nixbits,
  testers,
}:
let
  git' = symlinkJoin {
    pname = git.name;
    inherit (git) version;

    paths = [
      git
      nixbits.git-branch-prune
      nixbits.git-fetch-dir
      nixbits.git-track
    ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/git \
        --set GIT_CONFIG_GLOBAL ${nixbits.git-config}
    '';

    meta = {
      inherit (git.meta)
        name
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

        author = runCommand "test-git-author" { nativeBuildInputs = [ git ]; } ''
          expected="Joshua Peek"
          actual="$(git config get user.name)"
          if [[ "$actual" != "$expected" ]]; then
            echo "expected, '$expected' but was '$actual'"
            return 1
          fi
          touch $out
        '';

        default-branch = runCommand "test-git-default-branch" { nativeBuildInputs = [ git ]; } ''
          git init
          if [[ "$(git branch --show-current)" != "main" ]]; then
            echo "expected, 'main' but was '$(git branch --show-current)'"
            return 1
          fi
          touch $out
        '';
      };
  }
)
