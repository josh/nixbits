{ lib, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  name = "claude-skills";

  __structuredAttrs = true;

  buildCommand = ''
    mkdir -p $out
    cp -R ${../.claude/skills/gh} $out/gh
    cp -R ${../.claude/skills/jj-describe} $out/jj-describe
  '';

  meta = {
    description = "Skills for Claude Code";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
