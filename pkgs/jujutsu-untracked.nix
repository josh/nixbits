{
  lib,
  writeShellApplication,
  runCommand,
  writeText,
  coreutils,
  git,
  jujutsu,
  nixbits,
  git-config ? nixbits.git-config,
  jujutsu-config ? nixbits.jujutsu-config,
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
    GIT_CONFIG_GLOBAL = git-config;
    JJ_CONFIG = jujutsu-config;
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
      mkOverrideTest =
        name: initArgs:
        let
          jj-untracked = nixbits.jujutsu-untracked.override {
            git-config = writeText "jj-untracked-git-config" ''
              [core]
              excludesFile = ${writeText "jj-untracked-gitignore" "tracked-ignored.txt\n"}
            '';
            jujutsu-config = writeText "jj-untracked-config.toml" ''
              [user]
              name = "Override Author"
              email = "override@example.com"
              [snapshot]
              auto-track = "glob:tracked*"
            '';
          };
        in
        runCommand "test-jj-untracked-${name}-config-overrides"
          {
            nativeBuildInputs = [
              jujutsu
              jj-untracked
            ];
          }
          ''
            export HOME="$PWD/home"
            unset GIT_CONFIG_GLOBAL JJ_CONFIG
            mkdir -p "$HOME" repo
            cd repo
            jj git init ${initArgs}
            touch tracked.txt tracked-ignored.txt manual.txt

            actual="$(jj-untracked)"
            expected=$(printf 'manual.txt\ntracked-ignored.txt')
            if [[ "$actual" != "$expected" ]]; then
              echo "expected '$expected' but was '$actual'" >&2
              exit 1
            fi
            test "$(jj file list --ignore-working-copy)" = "tracked.txt"
            touch $out
          '';
    in
    {
      colocated = mkTest "colocated" "--colocate";
      non-colocated = mkTest "non-colocated" "--no-colocate";
      colocated-config-overrides = mkOverrideTest "colocated" "--colocate";
      non-colocated-config-overrides = mkOverrideTest "non-colocated" "--no-colocate";
    };

  meta = {
    description = "List files not tracked by jj, excluding the .jj store";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
