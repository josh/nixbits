{
  lib,
  writeShellApplication,
  runCommand,
  coreutils,
  git,
  jujutsu,
  nixbits,
}:
writeShellApplication {
  name = "jj-untracked";
  runtimeInputs = [
    coreutils
    git
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = nixbits.git-config;
    JJ_CONFIG = nixbits.jujutsu-config;
  };
  text = builtins.readFile ./jujutsu-untracked.bash;

  passthru.tests =
    let
      mkTest =
        name: initArgs:
        runCommand "test-jj-untracked-${name}"
          {
            nativeBuildInputs = [
              git
              jujutsu
              nixbits.jujutsu-untracked
            ];
          }
          ''
            export JJ_CONFIG=${nixbits.jujutsu-config}
            export GIT_CONFIG_GLOBAL=${nixbits.git-config}

            jj git init ${initArgs}
            touch tracked.txt
            echo "ignored/" > .gitignore
            mkdir ignored
            touch ignored/junk.txt
            jj status > /dev/null

            actual="$(jj-untracked)"
            if [[ "$actual" != "ignored/" ]]; then
              echo "expected 'ignored/' but was '$actual'" >&2
              exit 1
            fi
            touch $out
          '';
    in
    {
      colocated = mkTest "colocated" "--colocate";
      non-colocated = mkTest "non-colocated" "--no-colocate";
    };

  meta = {
    description = "List files not tracked by jj, excluding the .jj store";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
