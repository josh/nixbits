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

    init.defaultBranch = "main";
  };
in
config.overrideAttrs {
  allowedReferences = [ ];
  allowedRequisites = [ ];

  outputHash = "sha256-G/bBLI1PLGSVMmZ7PqDTIzBgxqOWXLsTlgxaV/gzl80=";
  outputHashAlgo = "sha256";
  outputHashMode = "nar";

  meta = {
    description = "git config";
    platforms = lib.platforms.all;
  };
}
