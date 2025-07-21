{
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
      nixbits.jujutsu-pull
      watchman
    ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/jj \
        --set JJ_CONFIG ${nixbits.jujutsu-config} \
        --set XDG_CONFIG_HOME ${nixbits.jujutsu-xdg-config-home}
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
      };
  }
)
