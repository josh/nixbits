{
  lib,
  stdenvNoCC,
  makeWrapper,
  runCommand,
  writeShellScript,
  python3,
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
  name = "healthchecks-apply";

  __structuredAttrs = true;

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
    ++ (lib.lists.optionals (healthchecksConfig.delete or false) [
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

  passthru.tests =
    let
      healthchecks-apply = finalAttrs.finalPackage;

      checksFixture = builtins.toFile "checks.json" ''
        [{"slug":"test-check","timeout":60,"grace":60}]
      '';
      wrapped = import ./healthchecks-apply.nix {
        inherit
          lib
          stdenvNoCC
          runCommand
          makeWrapper
          python3
          writeShellScript
          ;
        healthchecksConfig = {
          apiURL = "http://127.0.0.1:1";
          apiKeyCommand = "${writeShellScript "fake-api-key" "echo test-token"}";
          checksPath = checksFixture;
          delete = true;
        };
      };
    in
    {
      help = runCommand "test-healthchecks-apply-help" { nativeBuildInputs = [ healthchecks-apply ]; } ''
        healthchecks-apply --help
        touch $out
      '';

      wrapper-env = runCommand "test-healthchecks-apply-wrapper-env" { } ''
        grep --quiet 'HC_API_URL' ${wrapped}/bin/healthchecks-apply
        grep --quiet 'command:' ${wrapped}/bin/healthchecks-apply
        grep --quiet -- '--delete' ${wrapped}/bin/healthchecks-apply
        grep --quiet '${checksFixture}' ${wrapped}/bin/healthchecks-apply
        touch $out
      '';

      wrapper-offline-skip =
        runCommand "test-healthchecks-apply-wrapper-offline-skip" { nativeBuildInputs = [ wrapped ]; }
          ''
            healthchecks-apply --dry-run --allow-hc-offline 2>err.log
            grep --quiet 'offline' err.log
            touch $out
          '';
    };

  meta = {
    description = "Apply local healthchecks configs to a healthchecks.io server";
    license = lib.licenses.mit;
    mainProgram = "healthchecks-apply";
    platforms = lib.platforms.all;
  };
})
