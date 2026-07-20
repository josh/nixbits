{
  symlinkJoin,
  # keep-sorted start
  claude-code,
  codex,
  opencode,
  # keep-sorted end
}:
symlinkJoin {
  name = "ai-utils-path";
  paths = [
    # keep-sorted start
    claude-code
    codex
    opencode
    # keep-sorted end
  ];
  meta.description = "Favorite AI utilities";
}
