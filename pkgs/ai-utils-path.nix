{
  lib,
  pkgs,
  symlinkJoin,
  # keep-sorted start
  claude-code,
  codex,
  github-copilot-cli,
  llm,
  # keep-sorted end
  opencode ? null,
  nixbits,
}:
let
  llm' = if llm == pkgs.llm then nixbits.llm else llm;

  opencode' =
    if opencode == null && (builtins.hasAttr "opencode" pkgs) then pkgs.opencode else opencode;
in
symlinkJoin {
  name = "ai-utils-path";
  paths = [
    # keep-sorted start
    claude-code
    codex
    github-copilot-cli
    llm'
    # keep-sorted end
  ]
  ++ (lib.lists.optional (opencode' != null) opencode');
  meta.description = "Favorite AI utilities";
}
