{
  config,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.modules.default ];

  package = pkgs.gnugrep;
  wrapperImplementation = "binary";

  env.GREP_COLORS = "mt=1;32";
  flags."--color" = "auto";
  flagSeparator = "=";

  drv.meta.description = "Pattern search tool with colored output enabled";

  passthru.tests.version = pkgs.testers.testVersion {
    package = config.wrapper;
    command = "grep --version";
    inherit (config.wrapper) version;
  };
}
