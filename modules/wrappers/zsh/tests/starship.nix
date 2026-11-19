{
  runCommand,
  starship,
  wlibEvalPackage,
  writeShellScriptBin,
  writeText,
}:
let
  promptConfig = writeText "starship.toml" ''
    add_newline = false
    format = "nixbits-test-prompt"
  '';
  configuredStarship = writeShellScriptBin "starship" ''
    export STARSHIP_CONFIG=${promptConfig}
    exec ${starship}/bin/starship "$@"
  '';
  shell = wlibEvalPackage [
    ../../zsh.nix
    {
      starship.enable = true;
      starship.package = configuredStarship;
    }
  ];
in
runCommand "test-zsh-starship" { } ''
  export HOME="$PWD" TERM=xterm-256color
  ${shell}/bin/zsh -eic 'print -P -- "$PROMPT"' >prompt
  grep -Fx 'nixbits-test-prompt' prompt
  touch "$out"
''
