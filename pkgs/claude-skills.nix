{ lib, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  name = "claude-skills";

  buildCommand = ''
    mkdir -p $out
    cp -R ${../.claude/skills/jj} $out/jj
  '';

  meta = {
    description = "Claude Skills";
    platforms = lib.platforms.all;
  };
}
