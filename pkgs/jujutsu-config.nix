{ lib, writers }:
let
  config = writers.writeTOML "jj-config.toml" {
    user = {
      name = "Joshua Peek";
      email = "josh@users.noreply.github.com";
    };

    ui = {
      paginate = "never";
    };
  };
in
config.overrideAttrs {
  meta = {
    description = "jujutsu config";
    platforms = lib.platforms.all;
  };
}
