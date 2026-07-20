{
  lib,
  pkgs,
  symlinkJoin,
  # keep-sorted start
  claude-code,
  codex,
  # keep-sorted end
  opencode ? null,
}:
let
  opencode' =
    if opencode == null && (builtins.hasAttr "opencode" pkgs) then pkgs.opencode else opencode;
in
symlinkJoin {
  name = "ai-utils-path";
  paths = [
    # keep-sorted start
    claude-code
    codex
    # keep-sorted end
  ]
  ++ (lib.lists.optional (opencode' != null) opencode');
  meta.description = "Favorite AI utilities";
}
