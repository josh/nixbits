{
  lib,
  pkgs,
  symlinkJoin,
  # keep-sorted start
  claude-code,
  codex,
  gemini-cli,
  github-copilot-cli,
  llm,
  # keep-sorted end
  # keep-sorted start
  crush ? null,
  cursor-cli ? null,
  opencode ? null,
  # keep-sorted end
  nixbits,
}:
let
  llm' = if llm == pkgs.llm then nixbits.llm else llm;

  # FIXME: Always available in nixpkgs-25.11
  crush' = if crush == null && (builtins.hasAttr "crush" pkgs) then pkgs.crush else crush;
  cursor-cli' =
    if cursor-cli == null && (builtins.hasAttr "cursor-cli" pkgs) then pkgs.cursor-cli else cursor-cli;
  opencode' =
    if opencode == null && (builtins.hasAttr "opencode" pkgs) then pkgs.opencode else opencode;
in
symlinkJoin {
  name = "ai-utils-path";
  paths = [
    # keep-sorted start
    claude-code
    codex
    gemini-cli
    github-copilot-cli
    llm'
    # keep-sorted end
  ]
  ++ (lib.lists.optional (crush' != null) crush')
  ++ (lib.lists.optional (cursor-cli' != null) cursor-cli')
  ++ (lib.lists.optional (opencode' != null) opencode');
  meta.description = "Favorite AI utilities";
}
