{ lib, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  name = "claude-skills";

  buildCommand = ''
    mkdir -p $out
    cp -R ${../.claude/skills/gh} $out/gh
    cp -R ${../.claude/skills/jj-describe} $out/jj-describe
  '';

  meta = {
    description = "Claude Skills";
    platforms = lib.platforms.all;
  };
}
