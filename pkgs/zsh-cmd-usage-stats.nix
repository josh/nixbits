{
  writeShellApplication,
  coreutils,
  gnugrep,
}:
writeShellApplication {
  name = "zsh-cmd-usage-stats";
  runtimeInputs = [
    coreutils
    gnugrep
  ];
  inheritPath = false;
  text = builtins.readFile ./zsh-cmd-usage-stats.bash;
}
