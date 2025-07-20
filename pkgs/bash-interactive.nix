{
  lib,
  stdenvNoCC,
  runCommand,
  symlinkJoin,
  bash,
  eza,
  fzf,
  shellcheck-minimal,
  starship,
  nixbits,
  nur,
}:
let
  inherit (nixbits) direnv;
  inherit (nur.repos.josh) iterm2-shell-integration;

  path = symlinkJoin {
    name = "bash-path";
    paths = [
      direnv
    ];
  };

  direnv-init = runCommand "direnv-init" { nativeBuildInputs = [ direnv ]; } ''
    direnv hook bash >$out
  '';
  fzf-init = runCommand "fzf-init" { nativeBuildInputs = [ fzf ]; } ''
    fzf --bash >$out
  '';
  starship-init = runCommand "starship-init" { nativeBuildInputs = [ starship ]; } ''
    starship init bash --print-full-init >$out
  '';
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "bash-interactive";

  __structuredAttrs = true;

  text = ''
    if [[ $- != *i* ]]; then
      echo "Error: This script must be run in an interactive shell"
      exit 1
    fi

    export PATH=${path}/bin:$PATH

    if [ -d "''${XDG_STATE_HOME:-$HOME/.local/state}/bash" ]; then
      HISTFILE="''${XDG_STATE_HOME:-$HOME/.local/state}/bash/history"
    fi

    source ${direnv-init}
    source ${fzf-init}
    source ${starship-init}

    alias ls='${lib.getExe eza}'
    alias ll='${lib.getExe eza} --long'
    alias la='${lib.getExe eza} --all'
    alias lt='${lib.getExe eza} --tree'
    alias lla='${lib.getExe eza} --long --all'
  ''
  + (lib.strings.optionalString stdenvNoCC.isDarwin ''
    if [ -n "$ITERM_SESSION_ID" ]; then
      PATH="${iterm2-shell-integration}/bin:$PATH"
      ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=1 source ${iterm2-shell-integration}/share/iterm2-shell-integration/iterm2_shell_integration.zsh
      it2tip
    fi
  '');

  nativeBuildInputs = [
    shellcheck-minimal
  ];

  buildCommand = ''
    echo -n "$text" >"$out"

    runHook preCheck
    ${bash}/bin/bash -n "$out"
    shellcheck --shell=bash "$out" --external-sources
    runHook postCheck
  '';

  passthru.tests = {
    script = runCommand "bash-script" { nativeBuildInputs = [ bash ]; } ''
      export HOME=$(mktemp -d)
      if ! bash ${finalAttrs.finalPackage}; then
        touch $out
      fi
    '';

    interactive = runCommand "bash-interactive" { nativeBuildInputs = [ bash ]; } ''
      export HOME=$(mktemp -d)
      bash -i ${finalAttrs.finalPackage}
      touch $out
    '';

    login = runCommand "bash-login" { nativeBuildInputs = [ bash ]; } ''
      export HOME=$(mktemp -d)
      if ! bash -l ${finalAttrs.finalPackage}; then
        touch $out
      fi
    '';

    interactive-login-interactive =
      runCommand "bash-interactive-login-interactive" { nativeBuildInputs = [ bash ]; }
        ''
          export HOME=$(mktemp -d)
          bash -l -i ${finalAttrs.finalPackage}
          touch $out
        '';
  };

  meta = {
    description = "Bash interactive shell initialization";
    longDescription = ''
      Source via ~/.bashrc and ~/.bash_profile
    '';
  };
})
