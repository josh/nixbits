{
  lib,
  writers,
  neovim,
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
    };

    git = {
      executable-path = lib.getExe nixbits.git;
    };
  };
in
config.overrideAttrs {
  meta = {
    description = "jujutsu config";
    platforms = lib.platforms.all;
  };
}
