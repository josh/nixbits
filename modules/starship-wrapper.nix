{
  config,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.wrapperModules.starship ];

  wrapperImplementation = "binary";

  passthru.tests.version = pkgs.testers.testVersion {
    package = config.wrapper;
    command = "starship --version";
    inherit (config.wrapper) version;
  };
}
