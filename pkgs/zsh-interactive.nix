{
  lib,
  stdenvNoCC,
  runCommand,
  symlinkJoin,
  eza,
  fzf,
  neovim,
  starship,
  zoxide,
  zsh-autosuggestions,
  zsh-syntax-highlighting,
  zsh,
  nur,
  nixbits,
}:
let
  inherit (nixbits) direnv;
  inherit (nur.repos.josh) iterm2-shell-integration;

  path = symlinkJoin {
    name = "zsh-path";
    paths = [
      direnv
    ];
  };

  direnv-init = runCommand "direnv-init" { nativeBuildInputs = [ direnv ]; } ''
    direnv hook zsh >$out
  '';
  starship-init = runCommand "starship-init" { nativeBuildInputs = [ starship ]; } ''
    starship init zsh >$out
  '';
  fzf-init = runCommand "fzf-init" { nativeBuildInputs = [ fzf ]; } ''
    fzf --zsh >out
    substitute out $out \
      --replace-fail 'echo "fzf"' 'echo "${fzf}/bin/fzf"' \
      --replace-fail 'echo "fzf-tmux ' 'echo "${fzf}/bin/fzf-tmux '
  '';
  zoxide-init = runCommand "zoxide-init" { nativeBuildInputs = [ zoxide ]; } ''
    zoxide init zsh >out
    substitute out $out --replace-fail '\command zoxide' '${lib.getExe zoxide}'
  '';
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "zsh-interactive";

  __structuredAttrs = true;

  text = ''
    if [[ ! -o interactive ]]; then
      echo "Error: This script must be run in an interactive shell"
      exit 1
    fi

    typeset -U path fpath

    path+=("${path}/bin")

    # TODO: statically link this path
    if [ -d "$HOME/.local/state/nix/profiles/profile/share/zsh/site-functions" ]; then
      FPATH="$HOME/.local/state/nix/profiles/profile/share/zsh/site-functions:$FPATH"
    elif [ -d "$HOME/.local/state/nix/profile/share/zsh/site-functions" ]; then
      FPATH="$HOME/.local/state/nix/profile/share/zsh/site-functions:$FPATH"
    elif [ -d "$HOME/.nix-profile/share/zsh/site-functions" ]; then
      FPATH="$HOME/.nix-profile/share/zsh/site-functions:$FPATH"
    else
      echo "WARN: $HOME/.local/state/nix/profiles/profile/share/zsh/site-functions not found" >&2
    fi

    if [ -d "$XDG_CACHE_HOME" ]; then
      autoload -Uz compinit
      mkdir -p "$XDG_CACHE_HOME/zsh"
      compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
    else
      autoload -Uz compinit
      compinit
    fi

    HISTSIZE=50000
    SAVEHIST=50000

    setopt EXTENDED_HISTORY
    setopt APPEND_HISTORY
    setopt HIST_FIND_NO_DUPS
    setopt HIST_IGNORE_DUPS
    setopt HIST_IGNORE_SPACE

    # force emacs bindings
    bindkey -e

    # bash navigation
    autoload -U select-word-style
    select-word-style bash

    source ${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    bindkey '\t\t' autosuggest-accept

    source ${zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

    source ${direnv-init}
    source ${fzf-init}
    source ${starship-init}
    source ${zoxide-init}

    alias ls='${lib.getExe eza}'
    alias ll='${lib.getExe eza} --long'
    alias la='${lib.getExe eza} --all'
    alias lt='${lib.getExe eza} --tree'
    alias lla='${lib.getExe eza} --long --all'
  ''
  + (
    if stdenvNoCC.isDarwin then
      ''
        export EDITOR="${nixbits.bbedit-mas}/bin/bbedit --wait --resume"
      ''
    else
      # TODO: Use customized neovim
      ''
        export EDITOR="${neovim}/bin/nvim"
      ''
  )
  + (lib.strings.optionalString stdenvNoCC.isDarwin ''
    if [ -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Terminal/history" ]; then
      __sync_history() {
        echo "...syncing history"
        ${lib.getExe nixbits.zsh-session-prune}
        ${lib.getExe nixbits.zsh-history-sync}
      }
      autoload -Uz add-zsh-hook
      add-zsh-hook zshexit __sync_history
    fi

    if [ -n "$ITERM_SESSION_ID" ]; then
      path+=(${iterm2-shell-integration}/bin)
      ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=1 source ${iterm2-shell-integration}/share/iterm2-shell-integration/iterm2_shell_integration.bash
      it2tip
    fi
  '');

  buildCommand = ''
    echo -n "$text" >"$out"

    runHook preCheck
    ${zsh}/bin/zsh --no-exec "$out"
    runHook postCheck
  '';

  passthru.tests = {
    script = runCommand "zsh-script" { nativeBuildInputs = [ zsh ]; } ''
      export HOME=$(mktemp -d)
      if ! zsh ${finalAttrs.finalPackage}; then
        touch $out
      fi
    '';

    interactive = runCommand "zsh-interactive" { nativeBuildInputs = [ zsh ]; } ''
      export HOME=$(mktemp -d)
      zsh --interactive ${finalAttrs.finalPackage}
      touch $out
    '';

    login = runCommand "zsh-login" { nativeBuildInputs = [ zsh ]; } ''
      export HOME=$(mktemp -d)
      if ! zsh --login ${finalAttrs.finalPackage}; then
        touch $out
      fi
    '';

    interactive-login-interactive =
      runCommand "zsh-interactive-login-interactive" { nativeBuildInputs = [ zsh ]; }
        ''
          export HOME=$(mktemp -d)
          zsh --login --interactive ${finalAttrs.finalPackage}
          touch $out
        '';
  };

  meta = {
    description = "Zsh interactive shell initialization";
    longDescription = ''
      Source via ~/.zshrc and ~/.zprofile
    '';
  };
})
