{
  config,
  pkgs,
  wlib,
  ...
}:
let
  configFile = (pkgs.formats.toml { }).generate "herdr-config.toml" {
    onboarding = false;
    theme.name = "terminal";
  };
in
{
  imports = [ wlib.modules.default ];

  package = pkgs.herdr;
  wrapperImplementation = "binary";

  env.HERDR_CONFIG_PATH = "${configFile}";

  drv.meta.description = "Terminal workspace manager for AI coding agents, themed by the terminal's colors";

  passthru.tests = {
    version = pkgs.testers.testVersion {
      package = config.wrapper;
      command = "herdr --version";
      inherit (config.wrapper) version;
    };

    config = pkgs.runCommand "test-herdr-config" { nativeBuildInputs = [ config.wrapper ]; } ''
      export HOME="$PWD"
      herdr config check
      touch $out
    '';
  };
}
