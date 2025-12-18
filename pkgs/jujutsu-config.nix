{
  lib,
  writers,
  meld,
  neovim,
  vim,
  nixbits,
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
      executable-path = lib.getExe nixbits.git;
      private-commits = "description(glob:'wip:*')";
    };

    remotes.origin = {
      auto-track-bookmarks = "glob:push-*";
    };

    # No longer supported on darwin
    # merge-tools.kdiff3 = {
    #   program = lib.getExe kdiff3;
    # };

    merge-tools.meld = {
      program = lib.getExe meld;
    };

    merge-tools.vimdiff = {
      program = lib.getExe vim;
    };

    revset-aliases = {
      "closest_bookmark(to)" = "heads(::to & bookmarks())";
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
        "move"
        "--from"
        "closest_bookmark(@)"
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
        "--destination"
        "trunk()"
      ];
    };
  };
in
config.overrideAttrs {
  meta = {
    description = "jujutsu config";
    platforms = lib.platforms.all;
  };
}
