{
  lib,
  writers,
  kdiff3,
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
      # diff-editor = ":builtin";
      diff-editor = "kdiff3";
    };

    git = {
      executable-path = lib.getExe nixbits.git;
    };

    merge-tools.kdiff3 = {
      program = lib.getExe kdiff3;
    };

    merge-tools.meld = {
      program = lib.getExe meld;
    };

    merge-tools.vimdiff = {
      program = lib.getExe vim;
    };
  };
in
config.overrideAttrs {
  meta = {
    description = "jujutsu config";
    platforms = lib.platforms.all;
  };
}
