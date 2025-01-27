{
  lib,
  formats,
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
    };

    init.defaultBranch = "main";

    push.autoSetupRemote = true;
  };
in
config.overrideAttrs {
  allowedReferences = [ ];
  allowedRequisites = [ ];

  outputHash = "sha256-rcaXWLCxXwgSTbf0zDE/ELK8CCbHSnFxMARDhFvVds0=";
  outputHashAlgo = "sha256";
  outputHashMode = "nar";

  meta = {
    description = "git config";
    platforms = lib.platforms.all;
  };
}
