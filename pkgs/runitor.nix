{
  lib,
  stdenvNoCC,
  makeWrapper,
  runitor,
  coreutils,
  healthchecksApiUrl ? null,
  healthchecksPingKey ? null,
  healthchecksPingKeyCommand ? null,
  healthchecksApiRetries ? null,
  healthchecksApiTimeout ? null,
  checkProgram ? null,
  checkProgramTimeout ? 0,
  checkName ? checkSlug,
  checkSlug ? null,
  checkTimeout ? null,
  checkSchedule ? null,
  checkTZ ? "UTC",
  # One hour
  checkGrace ? 3600,
}:
let
  isPresent = s: s != null && s != "";

  toExePath = path: if lib.attrsets.isDerivation path then lib.getExe path else path;

  checkSlug' =
    if (isPresent checkSlug) then
      checkSlug
    else if (isPresent checkName) then
      # Allowed characters: a-z, 0-9, hyphens, underscores.
      (lib.strings.toLower (lib.strings.replaceStrings [ " " ] [ "-" ] checkName))
    else
      null;

  name = if (isPresent checkSlug') then "runitor-${checkSlug'}" else "runitor";

  healthcheckConfig =
    assert lib.asserts.assertMsg (
      checkTimeout == null || checkSchedule == null
    ) "Both timeout and schedule cannot be set";
    {
      slug = checkSlug';
      name = checkName;
      grace = checkGrace;
    }
    // lib.attrsets.optionalAttrs (checkSchedule != null) {
      schedule = checkSchedule;
      tz = checkTZ;
    }
    // lib.attrsets.optionalAttrs (checkTimeout != null) {
      timeout = checkTimeout;
    };
in
stdenvNoCC.mkDerivation (_finalAttrs: {
  __structuredAttrs = true;

  inherit name;

  nativeBuildInputs = [ makeWrapper ];

  makeWrapperArgs =
    (lib.lists.optionals (isPresent healthchecksApiUrl) [
      "--set"
      "HC_API_URL"
      healthchecksApiUrl
    ])
    ++ (lib.lists.optionals (isPresent healthchecksApiRetries) [
      "--append-flags"
      "-api-retries=${builtins.toString healthchecksApiRetries}"
    ])
    ++ (lib.lists.optionals (isPresent healthchecksApiTimeout) [
      "--append-flags"
      "-api-timeout=${builtins.toString healthchecksApiTimeout}"
    ])
    ++ (lib.lists.optionals (isPresent healthchecksPingKey) [
      "--set"
      "HC_PING_KEY"
      healthchecksPingKey
    ])
    ++ (lib.lists.optionals (isPresent healthchecksPingKeyCommand) [
      "--run"
      "export HC_PING_KEY=$(${toExePath healthchecksPingKeyCommand})"
    ])
    ++ (lib.lists.optionals (isPresent healthcheckConfig.slug) [
      "--set"
      "CHECK_SLUG"
      healthcheckConfig.slug
    ])
    ++ (lib.lists.optionals ((isPresent checkProgram) && checkProgramTimeout != 0) [
      "--append-flags"
      "-- ${coreutils}/bin/timeout ${builtins.toString checkProgramTimeout}s ${lib.getExe checkProgram}"
    ])
    ++ (lib.lists.optionals ((isPresent checkProgram) && checkProgramTimeout == 0) [
      "--append-flags"
      "-- ${lib.getExe checkProgram}"
    ]);

  healthcheckSlug = healthcheckConfig.slug;
  healthcheckConfig = builtins.toJSON healthcheckConfig;

  outputs = [
    "out"
    "healthcheck"
  ];

  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${lib.getExe runitor} $out/bin/$name "''${makeWrapperArgs[@]}"

    if [ -n "$healthcheckSlug" ]; then
      mkdir -p $out/etc/healthchecks $healthcheck/etc/healthchecks
      echo "$healthcheckConfig" >"$out/etc/healthchecks/$healthcheckSlug.json"
      echo "$healthcheckConfig" >"$healthcheck/etc/healthchecks/$healthcheckSlug.json"
    else
      touch "$healthcheck"
    fi
  '';

  meta = {
    description = "Wrapper for healthchecks.io runitor";
    mainProgram = name;
    inherit (runitor.meta) platforms;
  };
})
