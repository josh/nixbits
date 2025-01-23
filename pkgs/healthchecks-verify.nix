{
  lib,
  writeShellApplication,
  coreutils,
  curl,
  findutils,
  gnugrep,
  jq,
  runtimeEnv ? { },
  healthchecksConfig ? { },
}:
let
  toExePath = path: if lib.attrsets.isDerivation path then lib.getExe path else path;
in
writeShellApplication {
  name = "healthchecks-verify";
  runtimeEnv =
    {
      PATH = lib.strings.makeBinPath [
        coreutils
        curl
        findutils
        gnugrep
        jq
      ];
    }
    // (lib.attrsets.optionalAttrs (healthchecksConfig ? apiURL) {
      HC_API_URL = healthchecksConfig.apiURL;
    })
    // (lib.attrsets.optionalAttrs (healthchecksConfig ? apiKey) {
      HC_API_KEY = healthchecksConfig.apiKey;
    })
    // (lib.attrsets.optionalAttrs (healthchecksConfig ? apiKeyFile) {
      HC_API_KEY = "file:${healthchecksConfig.apiKeyFile}";
    })
    // (lib.attrsets.optionalAttrs (healthchecksConfig ? apiKeyCommand) {
      HC_API_KEY = "command:${toExePath healthchecksConfig.apiKeyCommand}";
    })
    // (lib.attrsets.optionalAttrs (healthchecksConfig ? checksPath) {
      HC_CHECKS_PATH = "${healthchecksConfig.checksPath}";
    });

  text = builtins.readFile ./healthchecks-verify.bash;
  meta = {
    description = "Verify local healthchecks slugs exist on healthchecks.io server";
    platforms = lib.platforms.all;
  };
}
