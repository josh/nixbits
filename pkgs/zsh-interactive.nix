{
  stdenvNoCC,
  runCommand,
  direnv,
  fzf,
  starship,
  zoxide,
  zsh-autosuggestions,
  zsh-syntax-highlighting,
  zsh,
}:
let
  direnv-init = runCommand "direnv-init" { nativeBuildInputs = [ direnv ]; } ''
    direnv hook zsh >$out
  '';
  starship-init = runCommand "starship-init" { nativeBuildInputs = [ starship ]; } ''
    starship init zsh >$out
  '';
  fzf-init = runCommand "fzf-init" { nativeBuildInputs = [ fzf ]; } ''
    fzf --zsh >$out
  '';
  zoxide-init = runCommand "zoxide-init" { nativeBuildInputs = [ zoxide ]; } ''
    zoxide init zsh >$out
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

    if [ -d "$XDG_CACHE_HOME" ]; then
      autoload -Uz compinit
      mkdir -p "$XDG_CACHE_HOME/zsh"
      compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
    else
      autoload -Uz compinit
      compinit
    fi

    source ${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    bindkey '\t\t' autosuggest-accept

    source ${zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

    source ${direnv-init}
    source ${fzf-init}
    source ${starship-init}
    source ${zoxide-init}
  '';

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
