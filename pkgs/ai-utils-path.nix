{
  pkgs,
  symlinkJoin,
  # keep-sorted start
  claude-code,
  codex,
  crush,
  cursor-cli,
  gemini-cli,
  llm,
  opencode,
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
    crush
    cursor-cli
    gemini-cli
    llm'
    opencode
    # keep-sorted end
  ];
  meta.description = "Favorite AI utilities";
}
