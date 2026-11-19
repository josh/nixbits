{
  nixbits,
  runCommand,
  wlibEvalPackage,
  zsh,
}:
let
  selective = wlibEvalPackage [
    ../../zsh.nix
    {
      zshenv.content = "unsetopt GLOBAL_RCS";
      ezaAliases.enable = true;
      history.save = 1234;
      history.options.HIST_IGNORE_DUPS = false;
    }
  ];
  profile = nixbits.zsh-interactive.override {
    zshModule = {
      ezaAliases.enable = false;
      autosuggestions.enable = false;
      history.save = 4321;
    };
  };
in
runCommand "test-zsh-interactive-profile" { } ''
  export HOME="$PWD/home" TERM=xterm-256color
  mkdir -p "$HOME/.nix-profile/share/zsh/site-functions"
  ${selective}/bin/zsh -o HIST_IGNORE_DUPS -ic '
    (( ''${+aliases[ll]} && SAVEHIST == 1234 )) &&
      [[ ! -o HIST_IGNORE_DUPS ]] && (( ! ''${+functions[z]} ))
  '
  ${zsh}/bin/zsh -dic '
    source "$1"
    (( HISTSIZE == 50000 && SAVEHIST == 4321 && ''${+functions[z]} )) &&
      [[ -o HIST_IGNORE_DUPS ]] &&
      (( ! ''${+aliases[ll]} && ! ''${+functions[_zsh_autosuggest_start]} ))
  ' zsh ${profile}
  touch "$out"
''
