{
  lib,
  writeShellApplication,
  runCommand,
  git,
  jujutsu,
  nixbits,
}:
writeShellApplication {
  name = "jj-init";
  runtimeInputs = [ jujutsu ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = nixbits.git-config;
    JJ_CONFIG = nixbits.jujutsu-config;
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
