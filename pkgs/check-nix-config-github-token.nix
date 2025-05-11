{
  writeShellApplication,
  gh,
  gnugrep,
  nix,
}:
writeShellApplication {
  name = "check-nix-config-github-token";
  runtimeInputs = [
    gh
    gnugrep
    nix
  ];
  inheritPath = false;
  text = builtins.readFile ./check-nix-config-github-token.bash;
  meta.description = "Check nix config for github.com access token";
}
