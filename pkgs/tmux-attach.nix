{
  lib,
  writeShellApplication,
  tmux,
}:
writeShellApplication {
  name = "tmux-attach";
  # Prepend to existing $PATH rather than use an isolated environment.
  runtimeInputs = [ tmux ];
  inheritPath = true;
  text = builtins.readFile ./tmux-attach.bash;
  meta = {
    description = "Attach to existing tmux session or create a new one";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
