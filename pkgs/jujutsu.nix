{
  lib,
  symlinkJoin,
  makeWrapper,
  runCommand,
  jujutsu,
  watchman,
  nixbits,
  testers,
}:
let
  jujutsu' = symlinkJoin {
    pname = "jujutsu";
    inherit (jujutsu) version;

    paths = [
      jujutsu
      nixbits.jujutsu-bookmark-clean
      nixbits.jujutsu-clone
      nixbits.jujutsu-git-set-upstream
      nixbits.jujutsu-new-main
      nixbits.jujutsu-pull
    ]
    ++ (lib.lists.optional watchman.meta.available watchman);
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/jj \
        --set JJ_CONFIG ${nixbits.jujutsu-config} \
        --set GIT_CONFIG_GLOBAL ${nixbits.git-config}
    '';

    meta = {
      inherit (jujutsu.meta)
        name
        description
        homepage
        platforms
        ;
      mainProgram = "jj";
    };
  };
in
jujutsu'.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        jujutsu = finalAttrs.finalPackage;
      in
      {
        version = testers.testVersion {
          package = jujutsu;
          command = "jj version";
          inherit (jujutsu) version;
        };

        author = runCommand "test-jj-author" { nativeBuildInputs = [ jujutsu ]; } ''
          expected="Joshua Peek"
          actual="$(jj config get user.name)"
          if [[ "$actual" != "$expected" ]]; then
            echo "expected, '$expected' but was '$actual'"
            return 1
          fi
          touch $out
        '';

        ignore = runCommand "test-jj-ignore" { nativeBuildInputs = [ jujutsu ]; } ''
          jj git init
          touch README.md
          mkdir .claude
          touch .claude/settings.local.json
          if ! jj file list | grep --quiet README.md; then
            echo "expected README.md to be tracked"
            return 1
          fi
          if jj file list | grep --quiet .claude/settings.local.json; then
            echo "expected .claude/settings.local.json to be ignored"
            return 1
          fi
          touch $out
        '';
      };
  }
)
