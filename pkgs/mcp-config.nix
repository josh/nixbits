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
  inherit config;

  nativeBuildInputs = [ jq ];

  buildCommand = ''
    jq '.config' <"$NIX_ATTRS_JSON_FILE" >"$out"
  '';

  meta = {
    description = "Model Context Protocol base config";
    platforms = lib.platforms.all;
  };
}
