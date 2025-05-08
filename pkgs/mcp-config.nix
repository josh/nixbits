{
  lib,
  stdenvNoCC,
  jq,
  nur,
  nixbits,
  extraMCPServers ? { },
}:
let
  inherit (nixbits) github-mcp-server;

  config = {
    mcpServers = {
      github.command = lib.getExe github-mcp-server;
    } // extraMCPServers;
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
