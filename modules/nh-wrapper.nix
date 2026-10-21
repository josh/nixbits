{
  config,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.modules.default ];

  package = pkgs.nh;
  wrapperImplementation = "binary";

  envDefault.NH_SEARCH_CHANNEL = "nixpkgs-unstable";

  drv.meta.description = "Nix helper searching nixpkgs-unstable by default";

  passthru.tests = {
    version = pkgs.testers.testVersion {
      package = config.wrapper;
      command = "nh --version";
      inherit (config.wrapper) version;
    };

    keeps-nh-flake = pkgs.runCommand "test-nh-keeps-nh-flake" { } ''
      if grep --quiet --text NH_FLAKE ${config.wrapper}/bin/nh; then
        echo "expected the wrapper to leave NH_FLAKE to the caller"
        return 1
      fi
      touch $out
    '';
  };
}
