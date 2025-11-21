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
  nixbits,
}:
let
  llm' = if llm == pkgs.llm then nixbits.llm else llm;
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
  # FIXME: Added in nixpkgs-25.11
  ++ lib.lists.optionals (lib.strings.versionAtLeast lib.version "25.10") (
    with pkgs;
    [
      crush
      cursor-cli
      opencode
    ]
  );
  meta.description = "Favorite AI utilities";
}
