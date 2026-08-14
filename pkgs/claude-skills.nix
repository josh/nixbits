{ lib, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  name = "claude-skills";

  __structuredAttrs = true;

  buildCommand = ''
    mkdir -p $out
    cp -R ${../.claude/skills/bug-hunt} $out/bug-hunt
    cp -R ${../.claude/skills/bump-pins} $out/bump-pins
    cp -R ${../.claude/skills/clean-room} $out/clean-room
    cp -R ${../.claude/skills/codex-triage} $out/codex-triage
    cp -R ${../.claude/skills/find-unpinned} $out/find-unpinned
    cp -R ${../.claude/skills/gh} $out/gh
    cp -R ${../.claude/skills/jj-describe} $out/jj-describe
    cp -R ${../.claude/skills/jj-release} $out/jj-release
  '';

  meta = {
    description = "Skills for Claude Code";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
