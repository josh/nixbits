{
  lib,
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
  meta = {
    description = "Bundle of AI command-line utilities";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
