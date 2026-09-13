{
  lib,
  writeShellApplication,
  jujutsu,
}:
writeShellApplication {
  name = "starship-jj-command";
  runtimeInputs = [ jujutsu ];
  inheritPath = false;
  text = builtins.readFile ./starship-jj-command.bash;

  meta = {
    description = "Print the current jj change and bookmarks for the Starship prompt";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
