let
  UTC = "UTC";
  ONE_HOUR = 1 * 60 * 60;
  isPresent = s: s != null && s != "";
in
{
  lib,
  stdenvNoCC,
  makeWrapper,
  runitor,
  healthchecksApiUrl ? null,
  healthchecksPingKey ? null,
  checkProgram ? null,
  checkName ? checkSlug,
  checkSlug ? null,
  checkTimeout ? null,
  checkSchedule ? null,
  checkTZ ? UTC,
  checkGrace ? ONE_HOUR,
}:
let
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
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  inherit name;
  mainProgram = name;

  nativeBuildInputs = [ makeWrapper ];

  makeWrapperArgs =
    (lib.lists.optionals (isPresent healthchecksApiUrl) [
      "--set"
      "HC_API_URL"
      healthchecksApiUrl
    ])
    ++ (lib.lists.optionals (isPresent healthchecksPingKey) [
      "--set"
      "HC_PING_KEY"
      healthchecksPingKey
    ])
    ++ (lib.lists.optionals (isPresent healthcheckConfig.slug) [
      "--set"
      "CHECK_SLUG"
      healthcheckConfig.slug
    ])
    ++ (lib.lists.optionals (isPresent checkProgram) [
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
    makeWrapper ${lib.getExe runitor} $out/bin/$mainProgram "''${makeWrapperArgs[@]}"

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
    inherit (runitor.meta) platforms;
    inherit (finalAttrs) mainProgram;
  };
})
