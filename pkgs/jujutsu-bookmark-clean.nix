{
  lib,
  writeShellApplication,
  runCommand,
  writeText,
  gnugrep,
  jujutsu,
  nixbits,
  git-config ? nixbits.git-config,
  jujutsu-config ? nixbits.jujutsu-config,
}:
writeShellApplication {
  name = "jj-bookmark-clean";
  runtimeInputs = [
    gnugrep
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = git-config;
    JJ_CONFIG = jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-bookmark-clean.bash;

  passthru.tests.config-overrides =
    let
      jj-bookmark-clean = nixbits.jujutsu-bookmark-clean.override {
        git-config = writeText "jj-bookmark-clean-git-config" ''
          [core]
          excludesFile = ${writeText "jj-bookmark-clean-gitignore" "ignored-by-override\n"}
        '';
        jujutsu-config = writeText "jj-bookmark-clean-config.toml" ''
          [user]
          name = "Override Author"
          email = "override@example.com"
          [revset-aliases]
          "trunk()" = "@-"
        '';
      };
    in
    runCommand "test-jj-bookmark-clean-config-overrides"
      {
        nativeBuildInputs = [
          jujutsu
          jj-bookmark-clean
        ];
      }
      ''
        export HOME="$PWD/home"
        export JJ_CONFIG=${nixbits.jujutsu-config} GIT_CONFIG_GLOBAL=${nixbits.git-config}
        mkdir -p "$HOME" repo
        cd repo
        jj git init
        jj describe --message base
        jj bookmark create main master
        jj new
        jj describe --message merged
        jj bookmark create push-merged
        jj new
        jj bookmark create push-unmerged
        unset GIT_CONFIG_GLOBAL JJ_CONFIG
        touch visible ignored-by-override
        jj-bookmark-clean

        actual="$(jj bookmark list --ignore-working-copy --template 'name ++ "\n"')"
        expected=$(printf 'main\nmaster\npush-unmerged')
        if [[ "$actual" != "$expected" ]]; then
          echo "expected '$expected' but was '$actual'" >&2
          exit 1
        fi
        test "$(jj file list --ignore-working-copy)" = "visible"
        touch $out
      '';

  meta = {
    description = "Clean up merged jj push-* bookmarks";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
