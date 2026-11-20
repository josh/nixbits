{
  nixbits,
  runCommand,
  zsh,
}:
let
  profile = nixbits.zsh-login;
  custom = nixbits.zsh-login.override {
    zshModule = {
      goPath.enable = false;
      zprofile.content = "export LOGIN_PROFILE_TEST=1";
    };
  };
in
runCommand "test-zsh-login-profile" { } ''
  export HOME="$PWD/home"
  mkdir "$HOME"
  unset GOPATH XDG_DATA_HOME
  ${zsh}/bin/zsh -dlc '
    source "$1"
    [[ $GOPATH == $HOME/.local/share/go && -z ''${LOGIN_PROFILE_TEST:-} ]]
  ' zsh ${profile}
  ${zsh}/bin/zsh -dlc '
    source "$1"
    [[ -z ''${GOPATH:-} && $LOGIN_PROFILE_TEST == 1 ]]
  ' zsh ${custom}
  touch "$out"
''
