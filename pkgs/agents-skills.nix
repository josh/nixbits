{ lib, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  name = "agents-skills";

  __structuredAttrs = true;

  buildCommand = ''
    mkdir -p $out
    cp -R ${../.agents/skills/bug-hunt} $out/bug-hunt
    cp -R ${../.agents/skills/clean-room} $out/clean-room
    cp -R ${../.agents/skills/gh} $out/gh
    cp -R ${../.agents/skills/jj-describe} $out/jj-describe
    cp -R ${../.agents/skills/jj-release} $out/jj-release
  '';

  meta = {
    description = "Agent skills for ChatGPT and Codex";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
