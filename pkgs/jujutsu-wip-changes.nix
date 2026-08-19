{
  lib,
  writeShellApplication,
  runCommand,
  git,
  jujutsu,
  nixbits,
}:
writeShellApplication {
  name = "jj-wip-changes";
  runtimeInputs = [ jujutsu ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = nixbits.git-config;
    JJ_CONFIG = nixbits.jujutsu-config;
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
