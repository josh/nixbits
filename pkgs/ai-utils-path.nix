{
  pkgs,
  symlinkJoin,
  claude-code,
  nixbits,
  llm,
}:
let
  llm' = if llm == pkgs.llm then nixbits.llm else llm;
in
symlinkJoin {
  name = "ai-utils-path";
  paths = [
    # keep-sorted start
    claude-code
    llm'
    # keep-sorted end
  ];
  meta.description = "Favorite AI utilities";
}
