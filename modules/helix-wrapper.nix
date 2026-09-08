{
  config,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.wrapperModules.helix ];

  wrapperImplementation = "binary";

  env.XDG_CONFIG_HOME = config.generatedConfig.placeholder;

  passthru.tests = {
    version = pkgs.testers.testVersion {
      package = config.wrapper;
      command = "hx --version";
      inherit (config.wrapper) version;
    };

    health = pkgs.runCommand "test-helix-health" { nativeBuildInputs = [ config.wrapper ]; } ''
      health="$(hx --health)"
      if grep --quiet malformed <<<"$health"; then
        echo "expected no malformed config, but was:"
        echo "$health"
        return 1
      fi
      touch $out
    '';
  };
}
