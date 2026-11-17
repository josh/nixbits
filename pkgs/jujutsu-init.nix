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
  name = "jj-init";
  runtimeInputs = [ jujutsu ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = git-config;
    JJ_CONFIG = jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-init.bash;

  passthru.tests =
    let
      setup = ''
        export JJ_CONFIG=${nixbits.jujutsu-config} GIT_CONFIG_GLOBAL=${nixbits.git-config} HOME="$PWD/home"
        mkdir -p "$HOME"

        assert_tracked() {
          local actual
          actual="$(jj bookmark list --tracked --template 'if(remote, name ++ "@" ++ remote ++ "\n")')"
          [ "$actual" = "$1" ] && return
          echo "expected tracked '$1' but was '$actual'" >&2
          exit 1
        }
      '';

      mkTest =
        name: script:
        runCommand "test-jj-init-${name}" {
          nativeBuildInputs = [
            git
            jujutsu
            nixbits.jujutsu-init
          ];
        } (setup + script + "\ntouch $out\n");

      mkClone = branch: ''
        git init --initial-branch=${branch} seed && cd seed || exit 1
        echo hello >README.md
        git add README.md && git commit --message initial
        cd .. && git clone --bare seed origin.git
        git clone origin.git work
        cd work || exit 1
      '';
    in
    {
      config-overrides =
        let
          jj-init = nixbits.jujutsu-init.override {
            git-config = writeText "jj-init-git-config" ''
              [core]
              excludesFile = ${writeText "jj-init-gitignore" "ignored-by-override\n"}
            '';
            jujutsu-config = writeText "jj-init-config.toml" ''
              [user]
              name = "Override Author"
              email = "override@example.com"
            '';
          };
        in
        runCommand "test-jj-init-config-overrides"
          {
            nativeBuildInputs = [
              git
              jujutsu
              jj-init
            ];
          }
          ''
            export HOME="$PWD/home"
            mkdir -p "$HOME" repo
            cd repo
            git init
            touch visible ignored-by-override
            jj-init
            test "$(jj log --ignore-working-copy --no-graph --revisions @ --template 'author.name()')" = "Override Author"
            test "$(jj log --ignore-working-copy --no-graph --revisions @ --template 'author.email()')" = "override@example.com"
            test "$(jj file list --ignore-working-copy)" = "visible"
            touch $out
          '';

      main = mkTest "main" (
        mkClone "main"
        + ''
          jj-init
          assert_tracked main@origin
        ''
      );

      master = mkTest "master" (
        mkClone "master"
        + ''
          jj-init
          assert_tracked master@origin
        ''
      );

      no-remote = mkTest "no-remote" ''
        mkdir solo && cd solo || exit 1
        git init
        jj-init
        assert_tracked ""
      '';
    };

  meta = {
    description = "Initialize a jj repo and track the remote trunk bookmark";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
