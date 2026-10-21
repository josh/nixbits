{
  config,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.wrapperModules.nh ];

  searchChannel = "nixpkgs-unstable";

  passthru.tests = {
    version = pkgs.testers.testVersion {
      package = config.wrapper;
      command = "nh --version";
      inherit (config.wrapper) version;
    };
  };
}
