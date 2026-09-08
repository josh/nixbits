{
  lib,
  stdenvNoCC,
  jq,
  extraSettings ? { },
}:
let
  settings = lib.attrsets.recursiveUpdate {
    attribution = {
      commit = "";
      pr = "";
      sessionUrl = false;
    };
    feedbackDrafts = "off";
  } extraSettings;
in
stdenvNoCC.mkDerivation {
  name = "claude-managed-settings.json";

  __structuredAttrs = true;

  nativeBuildInputs = [ jq ];

  inherit settings;

  buildCommand = ''
    jq '.settings' <"$NIX_ATTRS_JSON_FILE" >"$out"
  '';

  meta = {
    description = "Managed settings policy for Claude Code";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
