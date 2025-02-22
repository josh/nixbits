{
  lib,
  formats,
  gh,
}:
let
  gitIni = formats.gitIni { };
  config = gitIni.generate "git-config" {
    user = {
      name = "Joshua Peek";
      email = "josh@users.noreply.github.com";
    };

    alias = {
      co = "checkout";
      ci = "commit --verbose";
    };

    init.defaultBranch = "main";

    push.autoSetupRemote = true;

    credential = {
      "https://github.com".helper = "${lib.getExe gh} auth git-credential";
      "https://gist.github.com".helper = "${lib.getExe gh} auth git-credential";
    };
  };
in
config.overrideAttrs {
  meta = {
    description = "git config";
    platforms = lib.platforms.all;
  };
}
