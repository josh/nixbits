{
  lib,
  python3,
  stdenvNoCC,
  runCommand,
  makeWrapper,
  healthchecksConfig ? { },
}:
let
  toExePath = path: if lib.attrsets.isDerivation path then lib.getExe path else path;
  python = python3.withPackages (ps: [
    ps.requests
    ps.click
  ]);
in
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  name = "healthchecks-apply";

  nativeBuildInputs = [ makeWrapper ];

  makeWrapperArgs =
    (lib.lists.optionals (healthchecksConfig ? checksPath) [
      "--set"
      "HC_CHECKS_PATH"
      "${healthchecksConfig.checksPath}"
    ])
    ++ (lib.lists.optionals (healthchecksConfig ? apiURL) [
      "--set"
      "HC_API_URL"
      healthchecksConfig.apiURL
    ])
    ++ (lib.lists.optionals (healthchecksConfig ? apiKey) [
      "--set"
      "HC_API_KEY"
      healthchecksConfig.apiKey
    ])
    ++ (lib.lists.optionals (healthchecksConfig ? apiKeyFile) [
      "--set"
      "HC_API_KEY"
      "file:${healthchecksConfig.apiKeyFile}"
    ])
    ++ (lib.lists.optionals (healthchecksConfig ? apiKeyCommand) [
      "--set"
      "HC_API_KEY"
      "command:${toExePath healthchecksConfig.apiKeyCommand}"
    ])
    ++ (lib.lists.optionals (healthchecksConfig ? delete) [
      "--add-flags"
      "--delete"
    ]);

  buildCommand = ''
    mkdir -p $out/bin
    (
      echo "#!${python.interpreter}"
      cat "${./healthchecks-apply.py}"
    ) >$out/bin/healthchecks-apply
    chmod +x $out/bin/healthchecks-apply

    if [ ''${#makeWrapperArgs[@]} -gt 0 ]; then
      wrapProgram $out/bin/healthchecks-apply "''${makeWrapperArgs[@]}"
    fi
  '';

  meta = {
    mainProgram = "healthchecks-apply";
    description = "Apply local healthchecks configs to a healthchecks.io server";
    platforms = lib.platforms.all;
  };

  passthru.tests =
    let
      healthchecks-apply = finalAttrs.finalPackage;
    in
    {
      help = runCommand "test-healthchecks-apply-help" { nativeBuildInputs = [ healthchecks-apply ]; } ''
        healthchecks-apply --help
        touch $out
      '';
    };
})
