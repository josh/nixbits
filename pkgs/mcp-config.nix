{
  lib,
  stdenvNoCC,
  jq,
  extraMCPServers ? { },
}:
let
  config = {
    mcpServers = {
      # Placeholder
    }
    // extraMCPServers;
  };
in
stdenvNoCC.mkDerivation {
  name = "mcp-config.json";

  __structuredAttrs = true;

  nativeBuildInputs = [ jq ];

  inherit config;

  buildCommand = ''
    jq '.config' <"$NIX_ATTRS_JSON_FILE" >"$out"
  '';

  meta = {
    description = "Model Context Protocol base config";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
