{
  lib,
  writeShellApplication,
  gh,
  github-mcp-server,
}:
writeShellApplication {
  name = "github-mcp-server";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      gh
      github-mcp-server
    ];
  };
  text = ''
    GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token)
    export GITHUB_PERSONAL_ACCESS_TOKEN
    exec github-mcp-server stdio
  '';
  meta = {
    inherit (github-mcp-server.meta) description homepage;
    platforms = lib.platforms.all;
  };
}
