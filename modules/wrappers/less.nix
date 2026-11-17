{
  config,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.modules.default ];

  package = pkgs.less;
  wrapperImplementation = "binary";

  env.LESSHISTFILE = "-";

  drv.meta.description = "Terminal pager with the history file disabled";

  passthru.tests.version = pkgs.testers.testVersion {
    package = config.wrapper;
    command = "less --version";
    inherit (config.wrapper) version;
  };
}
