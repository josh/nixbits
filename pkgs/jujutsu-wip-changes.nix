{
  lib,
  writeShellApplication,
  runCommand,
  writeText,
  git,
  jujutsu,
  nixbits,
  git-config ? nixbits.git-config,
  jujutsu-config ? nixbits.jujutsu-config,
}:
writeShellApplication {
  name = "jj-wip-changes";
  runtimeInputs = [ jujutsu ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = git-config;
    JJ_CONFIG = jujutsu-config;
  };
  text = builtins.readFile ./jujutsu-wip-changes.bash;

  passthru.tests =
    let
      setup = ''
        export JJ_CONFIG=${nixbits.jujutsu-config} GIT_CONFIG_GLOBAL=${nixbits.git-config} HOME="$PWD/home"
        mkdir -p "$HOME"
        git init --initial-branch=main seed && cd seed || exit 1
        echo hello >README.md
        git add README.md && git commit --message initial
        git checkout -b feature && git commit --allow-empty --message feature && git checkout main
        cd .. && git clone --bare seed origin.git
        jj git clone --colocate origin.git work
        cd work || exit 1

        assert_wip() {
          local out
          out="$(jj-wip-changes)"
          [ "$(grep --count . <<<"$out" || true)" = "$1" ] &&
            [ "$(grep --count '\*$' <<<"$out" || true)" = "$2" ] && return
          echo "expected $1 change(s), $2 unpushed, but was: $out" >&2
          exit 1
        }
      '';

      mkTest =
        name: script:
        runCommand "test-jj-wip-changes-${name}" {
          nativeBuildInputs = [
            git
            jujutsu
            nixbits.jujutsu-wip-changes
          ];
        } (setup + script + "\ntouch $out\n");
    in
    {
      config-overrides =
        let
          jj-wip-changes = nixbits.jujutsu-wip-changes.override {
            git-config = writeText "jj-wip-changes-git-config" ''
              [core]
              excludesFile = ${writeText "jj-wip-changes-gitignore" "tracked-ignored.txt\n"}
            '';
            jujutsu-config = writeText "jj-wip-changes-config.toml" ''
              [user]
              name = "Override Author"
              email = "override@example.com"
              [snapshot]
              auto-track = "glob:tracked*"
              [revset-aliases]
              "trunk()" = "root()"
            '';
          };
        in
        runCommand "test-jj-wip-changes-config-overrides"
          {
            nativeBuildInputs = [
              jujutsu
              jj-wip-changes
            ];
          }
          ''
            export HOME="$PWD/home"
            unset GIT_CONFIG_GLOBAL JJ_CONFIG
            mkdir -p "$HOME" repo
            cd repo
            jj git init
            test -z "$(jj-wip-changes)"

            touch manual.txt tracked-ignored.txt
            test -z "$(jj-wip-changes)"
            touch tracked.txt
            expected="$(jj log --ignore-working-copy --no-graph --revisions @ --template 'change_id.short(8)')*"
            actual="$(jj-wip-changes)"
            if [[ "$actual" != "$expected" ]]; then
              echo "expected '$expected' but was '$actual'" >&2
              exit 1
            fi
            test "$(jj file list --ignore-working-copy)" = "tracked.txt"
            touch $out
          '';

      local-work = mkTest "local-work" ''
        assert_wip 0 0
        echo change >>README.md
        assert_wip 1 1
        jj describe --message wip
        jj new
        assert_wip 1 1
      '';

      pushed-bookmark = mkTest "pushed-bookmark" ''
        jj bookmark track feature@origin
        assert_wip 1 0
      '';
    };

  meta = {
    description = "List change IDs still being worked on locally, marking unpushed ones with an asterisk";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
