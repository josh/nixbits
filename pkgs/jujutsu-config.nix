{
  lib,
  writers,
  runCommand,
  writeShellScriptBin,
  jujutsu,
  meld,
  neovim,
  vim,
  nixbits,
  git-package ? nixbits.git,
}:
let
  config = writers.writeTOML "jj-config.toml" {
    user = {
      name = "Joshua Peek";
      email = "josh@users.noreply.github.com";
    };

    ui = {
      default-command = [ "log" ];
      editor = lib.getExe neovim;
      paginate = "never";
      diff-editor = ":builtin";
    };

    git = {
      executable-path = lib.getExe git-package;
    };

    remotes.origin = {
      auto-track-bookmarks = "glob:push-*";
    };

    merge-tools.meld = {
      program = lib.getExe meld;
    };

    merge-tools.vimdiff = {
      program = lib.getExe vim;
    };

    revset-aliases = {
      "closest_pushable(to)" = "heads(::to & ~description(exact:\"\") & (~empty() | merges()))";
    };

    aliases = {
      fetch = [
        "git"
        "fetch"
        "--all-remotes"
      ];
      push = [
        "git"
        "push"
        "--all"
        "--deleted"
      ];
      tug = [
        "bookmark"
        "advance"
        "--to"
        "closest_pushable(@)"
      ];
      new-parent = [
        "new"
        "--no-edit"
        "--insert-before"
        "@"
      ];
      rebase-all = [
        "rebase"
        "--branch"
        "bookmarks()"
        "--onto"
        "trunk()"
      ];
    };
  };
in
config.overrideAttrs {
  passthru.tests.git-package-override =
    let
      customGit = writeShellScriptBin "git" "exit 1";
      customConfig = nixbits.jujutsu-config.override { git-package = customGit; };
    in
    runCommand "test-jj-config-git-package-override" { nativeBuildInputs = [ jujutsu ]; } ''
      export HOME="$PWD/home"
      mkdir -p "$HOME"
      test "$(JJ_CONFIG=${nixbits.jujutsu-config} jj config get git.executable-path)" = "${lib.getExe nixbits.git}"
      test "$(JJ_CONFIG=${customConfig} jj config get git.executable-path)" = "${lib.getExe customGit}"
      touch $out
    '';

  meta = {
    description = "Configuration for the Jujutsu version control system";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
