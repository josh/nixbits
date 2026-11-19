{ runCommand, wlibEvalPackage }:
let
  shell = wlibEvalPackage [
    ../../zsh.nix
    {
      appleTerminal.enable = true;
      # Stock macOS /etc/zshrc would initialize its own copy of the hook first.
      zshenv.content = "unsetopt GLOBAL_RCS";
      zshrc.content = ''
        HISTFILE="$HOME/.zsh_history"
        HISTSIZE=100
        SAVEHIST=100
      '';
    }
  ];
  restoreShell = shell.wrap { appleTerminal.sessionRestore.enable = true; };
in
runCommand "test-zsh-apple-terminal" { } ''
  export HOME="$PWD/home" TERM_PROGRAM=Apple_Terminal TERM_SESSION_ID=test-session
  mkdir "$HOME"
  session="$HOME/.zsh_sessions/$TERM_SESSION_ID"

  ${restoreShell}/bin/zsh -ic '
    (( ''${+functions[update_terminal_cwd]} )) || exit 1
    shell_session_history_check
    print -s -- "nixbits history fixture"
    shell_session_save_user_state() { print -r -- "NIXBITS_RESTORED=yes" >>"$1"; }
  '
  grep -Fx 'NIXBITS_RESTORED=yes' "$session.session"
  grep -F 'nixbits history fixture' "$session.history"
  grep -F 'nixbits history fixture' "$HOME/.zsh_history"

  mkdir "$HOME/directory with spaces"
  (cd "$HOME/directory with spaces" && ${shell}/bin/zsh -ic update_terminal_cwd) >cwd-report
  grep -F '/directory%20with%20spaces' cwd-report
  TERM_SESSION_ID=../elsewhere ${restoreShell}/bin/zsh -ic '[[ -z ''${SHELL_SESSION_DID_INIT+x} ]]'
  ${shell}/bin/zsh -eic '
    (( ''${+functions[update_terminal_cwd]} ))
    [[ -z ''${NIXBITS_RESTORED+x} && -z ''${SHELL_SESSION_DID_INIT+x} ]]
  '
  TERM_PROGRAM=rex ${restoreShell}/bin/zsh -eic '
    (( ! ''${+functions[update_terminal_cwd]} ))
    [[ -z ''${NIXBITS_RESTORED+x} && -z ''${SHELL_SESSION_DID_INIT+x} ]]
  '
  # Make the per-session file the only possible source of the history entry.
  : >"$HOME/.zsh_history"
  ${restoreShell}/bin/zsh -ic '
    [[ $NIXBITS_RESTORED == yes ]] && fc -ln 1 | grep -F "nixbits history fixture"
  '
  touch "$out"
''
