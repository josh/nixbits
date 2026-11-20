{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs) nixbits;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  eza = lib.getExe nixbits.eza;
  rexEditor = if nixbits.neorex.meta.available then nixbits.neorex else nixbits.neovim;
  iterm = pkgs.nur.repos.josh.iterm2-shell-integration;
in
{
  options = {
    uniquePaths.enable = lib.mkEnableOption "deduplication of path and fpath";
    rexTheme.enable = lib.mkEnableOption "Rex terminal color scheme detection";
    manPager.enable = lib.mkEnableOption "the bat man pager";
    emacsBindings.enable = lib.mkEnableOption "the Emacs keymap";
    bashWordStyle.enable = lib.mkEnableOption "Bash-style word navigation";
    ezaAliases.enable = lib.mkEnableOption "the ls, ll, la, lt and lla eza aliases";
    editorFallback.enable = lib.mkEnableOption "the platform and terminal-specific default EDITOR";
    iCloudHistory.enable = lib.mkEnableOption "history synchronization on exit when the iCloud history directory exists";
    iterm2.enable = lib.mkEnableOption "iTerm2 integration on macOS";
    sshKeychainProvider.enable = lib.mkEnableOption "the macOS keychain as the default OpenSSH security key provider";
  };

  config.zshrc.content = lib.mkMerge [
    (lib.mkIf config.uniquePaths.enable (lib.mkOrder 1200 "typeset -U path fpath"))
    (lib.mkIf config.rexTheme.enable (
      lib.mkOrder 1200 ''
        if [[ ''${TERM_PROGRAM:-} == rex && -z ''${THEME:-} ]]; then
          if [[ "$(${lib.getExe nixbits.term-scheme})" == light ]]; then
            export THEME=ansi_light COLORFGBG='0;15'
          else
            export THEME=ansi_dark COLORFGBG='15;0'
          fi
        fi
      ''
    ))
    (lib.mkIf config.manPager.enable (
      lib.mkOrder 1200 ''
        export MANPAGER="sh -c 'col -bx | ${lib.getExe nixbits.bat} --language=man --plain'"
      ''
    ))
    (lib.mkIf (config.direnv.enable && config.direnv.addToPath) (
      lib.mkOrder 1200 ''
        path=(${config.direnv.package}/bin $path)
      ''
    ))
    # ssh-add and ssh-keygen read this; ssh itself uses SecurityKeyProvider.
    (lib.mkIf (isDarwin && config.sshKeychainProvider.enable) (
      lib.mkOrder 1200 ''
        export SSH_SK_PROVIDER="''${SSH_SK_PROVIDER:-/usr/lib/ssh-keychain.dylib}"
      ''
    ))
    (lib.mkIf config.emacsBindings.enable (lib.mkOrder 1200 "bindkey -e"))
    (lib.mkIf config.bashWordStyle.enable (
      lib.mkOrder 1200 ''
        autoload -U select-word-style
        select-word-style bash
      ''
    ))
    (lib.mkIf config.ezaAliases.enable (
      lib.mkOrder 1520 ''
        alias ls='${eza}'
        alias ll='${eza} --long'
        alias la='${eza} --all'
        alias lt='${eza} --tree'
        alias lla='${eza} --long --all'
      ''
    ))
    (lib.mkIf config.editorFallback.enable (
      lib.mkOrder 1600 (
        if isDarwin then
          ''
            if [[ ''${TERM_PROGRAM:-} == rex ]]; then
              export EDITOR="''${EDITOR:-${lib.getExe rexEditor}}"
            else
              export EDITOR="''${EDITOR:-${nixbits.bbedit-mas}/bin/bbedit --wait --resume}"
            fi
          ''
        else
          ''
            export EDITOR="''${EDITOR:-${lib.getExe' pkgs.neovim "nvim"}}"
          ''
      )
    ))
    (lib.mkIf (isDarwin && config.iCloudHistory.enable) (
      lib.mkOrder 1600 ''
        if [[ -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Terminal/history" ]]; then
          __sync_history() {
            echo "...syncing history"
            ${lib.getExe nixbits.zsh-session-prune}
            ${lib.getExe nixbits.zsh-history-sync}
          }
          autoload -Uz add-zsh-hook
          add-zsh-hook zshexit __sync_history
        fi
      ''
    ))
    (lib.mkIf (isDarwin && config.iterm2.enable) (
      lib.mkOrder 1600 ''
        if [[ -n $ITERM_SESSION_ID ]]; then
          path=(${iterm}/bin $path)
          ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=1 source ${iterm}/share/iterm2-shell-integration/iterm2_shell_integration.zsh
        fi
      ''
    ))
  ];
}
