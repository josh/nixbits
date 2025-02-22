{ lib, writeShellApplication }:
writeShellApplication {
  name = "test-fonts";
  text = builtins.readFile ./test-fonts.bash;
  meta = {
    description = "Check if terminal can render edgecase fonts";
    platforms = lib.platforms.all;
  };
}
