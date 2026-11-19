{
  direnv,
  runCommand,
  wlibEvalPackage,
  writeShellScriptBin,
}:
let
  probe = writeShellScriptBin "direnv" ''
    if [[ $1 == export ]]; then
      echo "$*" >>"$DIRENV_CALLS"
    fi
    exec ${direnv}/bin/direnv "$@"
  '';
  shell = wlibEvalPackage [
    ../../zsh.nix
    {
      direnv.enable = true;
      direnv.package = probe;
    }
  ];
in
runCommand "test-zsh-direnv" { } ''
  export HOME="$PWD/home" DIRENV_CALLS="$PWD/calls"
  mkdir -p "$HOME" project
  echo 'export NIXBITS_DIRENV_TEST=loaded' > project/.envrc
  ${direnv}/bin/direnv allow project
  ${shell}/bin/zsh -eic '
    cd project
    [[ $NIXBITS_DIRENV_TEST == loaded ]]
    cd ..
    [[ -z ''${NIXBITS_DIRENV_TEST+x} ]]
  '
  grep -Fx 'export zsh' "$DIRENV_CALLS"
  touch "$out"
''
