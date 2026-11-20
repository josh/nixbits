{
  config,
  lib,
  pkgs,
  wlib,
  ...
}:
let
  direnv = lib.getExe' config.direnv.package "direnv";
  direnvHook = pkgs.runCommand "direnv-hook.zsh" { } ''
    # direnv embeds its running executable, which may be behind the configured wrapper.
    selfPath=$(${direnv} status --json | ${lib.getExe pkgs.jq} -er '.config.SelfPath')
    ${direnv} hook zsh >hook.zsh
    substitute hook.zsh "$out" --replace-fail "$selfPath" "${direnv}"
    ${pkgs.zsh}/bin/zsh -n "$out"
  '';
  fzfInit = pkgs.runCommand "fzf-init.zsh" { nativeBuildInputs = [ pkgs.nixbits.fzf ]; } ''
    fzf --zsh >out
    substitute out "$out" \
      --replace-fail 'echo "fzf"' 'echo "${pkgs.nixbits.fzf}/bin/fzf"' \
      --replace-fail 'echo "fzf-tmux ' 'echo "${pkgs.nixbits.fzf}/bin/fzf-tmux '
  '';
  starshipInit =
    pkgs.runCommand "starship-init.zsh" { nativeBuildInputs = [ config.starship.package ]; }
      ''
        TERM=xterm-256color starship init zsh --print-full-init >"$out"
        ${pkgs.zsh}/bin/zsh -n "$out"
      '';
in
{
  imports = [
    wlib.wrapperModules.zsh
    ./zsh/interactive-profile.nix
    ./zsh/login-profile.nix
    ./zsh/history.nix
    ./zsh/terminal.nix
  ];

  options = {
    appleTerminal.enable = lib.mkEnableOption "working-directory reporting in Apple Terminal";
    appleTerminal.sessionRestore.enable = lib.mkEnableOption "Apple Terminal per-session history and execution of saved .session files";
    combiningChars.enable = lib.mkEnableOption "Apple’s locale-aware zsh combining character handling on macOS";
    completion.enable = lib.mkEnableOption "zsh completion initialization";
    completion.profileCache = lib.mkEnableOption "profile completion discovery and a versioned XDG compdump";
    autosuggestions.enable = lib.mkEnableOption "zsh autosuggestions with double-Tab acceptance";
    fzf.enable = lib.mkEnableOption "fzf shell widgets and completion";
    syntaxHighlighting.enable = lib.mkEnableOption "zsh syntax highlighting";
    direnv.beforePrompt = lib.mkEnableOption "loading direnv before the prompt and fzf widgets";
    direnv.addToPath = lib.mkEnableOption "adding the configured direnv executable to PATH";
    direnv.enable = lib.mkEnableOption "direnv shell integration";
    direnv.package = lib.mkPackageOption pkgs.nixbits "direnv" { };
    preferSystemLog.enable = lib.mkEnableOption "disabling the zsh log builtin so macOS log is found on PATH";
    starship.enable = lib.mkEnableOption "the Starship prompt";
    starship.package = lib.mkOption {
      type = lib.types.package;
      default = if pkgs.nixbits.starship.meta.available then pkgs.nixbits.starship else pkgs.starship;
      description = "Starship package used to initialize and render the prompt.";
    };
    terminfoKeyBindings.enable = lib.mkEnableOption "zsh key bindings from terminal capabilities";
    zoxide.enable = lib.mkEnableOption "zoxide shell integration";
    zoxide.package = lib.mkPackageOption pkgs "zoxide" { };
    zp.enable = lib.mkEnableOption "the zp project navigation function";
    zp.package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nixbits.zp-zsh;
      description = "Sourceable zp function with the desired Git and Jujutsu commands.";
    };
  };

  config = {
    # zp uses z to enter a checkout. Consumers can also supply their own z.
    zoxide.enable = lib.mkIf config.zp.enable (lib.mkDefault true);
    zshrc.content = lib.mkMerge [
      (lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && config.combiningChars.enable) (
        lib.mkAfter ''
          if [[ ! -x /usr/bin/locale || "$(/usr/bin/locale LC_CTYPE)" == UTF-8 ]]; then
            setopt COMBINING_CHARS
          fi
        ''
      ))
      (lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && config.appleTerminal.enable) (
        lib.mkAfter ''
          if [[ ''${TERM_PROGRAM:-} == Apple_Terminal ]]; then
            () {
              local ZDOTDIR="$HOME"
              # Apple uses the session ID as a filename under ~/.zsh_sessions.
              local TERM_SESSION_ID="''${TERM_SESSION_ID:-}"
              [[ $TERM_SESSION_ID == */* ]] && TERM_SESSION_ID=
              ${
                if config.appleTerminal.sessionRestore.enable then
                  ": \${SHELL_SESSION_HISTORY:=1}"
                else
                  "local SHELL_SESSIONS_DISABLE=1"
              }
              source ${../../pkgs/apple-zshrc/zshrc_Apple_Terminal}
            }
          fi
        ''
      ))
      (lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && config.preferSystemLog.enable) (
        lib.mkAfter "disable log"
      ))
      (lib.mkIf config.terminfoKeyBindings.enable (
        lib.mkAfter "source ${./zsh/terminfo-key-bindings.zsh}"
      ))
      (lib.mkIf config.completion.enable (
        lib.mkAfter (
          if config.completion.profileCache then
            "source ${./zsh/profile-completion.zsh}"
          else
            ''
              autoload -Uz compinit
              compinit -d "$HOME/.zcompdump"
            ''
        )
      ))
      (lib.mkIf config.autosuggestions.enable (
        lib.mkAfter ''
          source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
          bindkey '\t\t' autosuggest-accept
        ''
      ))
      (lib.mkIf (config.direnv.enable && config.direnv.beforePrompt) (lib.mkAfter "source ${direnvHook}"))
      (lib.mkIf config.fzf.enable (lib.mkAfter "source ${fzfInit}"))
      (lib.mkIf config.starship.enable (lib.mkAfter "source ${starshipInit}"))
      (lib.mkIf (config.direnv.enable && !config.direnv.beforePrompt) (
        lib.mkAfter "source ${direnvHook}"
      ))
      (lib.mkIf config.zoxide.enable (
        lib.mkAfter "source ${pkgs.nixbits.zoxide-init-zsh.override { zoxide = config.zoxide.package; }}"
      ))
      # Highlighting wraps the widgets registered above.
      (lib.mkIf config.syntaxHighlighting.enable (
        lib.mkAfter "source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
      ))
      (lib.mkIf config.zp.enable (lib.mkOrder 1700 "source ${config.zp.package}"))
    ];
  };
}
