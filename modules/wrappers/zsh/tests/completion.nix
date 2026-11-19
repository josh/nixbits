{ runCommand, wlibEvalPackage }:
let
  shell = wlibEvalPackage [
    ../../zsh.nix
    {
      completion.enable = true;
      zshrc.content = ''fpath=("$HOME/completions" $fpath)'';
    }
  ];
in
runCommand "test-zsh-completion" { } ''
  export HOME="$PWD/home"
  mkdir -p "$HOME/completions"
  echo '#compdef nixbits-fixture' >"$HOME/completions/_nixbits_fixture"
  ${shell}/bin/zsh -eic '
    [[ ''${_comps[nixbits-fixture]} == _nixbits_fixture ]]
    [[ -s $HOME/.zcompdump ]]
  '
  touch "$out"
''
