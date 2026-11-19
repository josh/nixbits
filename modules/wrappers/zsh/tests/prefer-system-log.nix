{ runCommand, wlibEvalPackage }:
let
  shell = wlibEvalPackage [
    ../../zsh.nix
    # Stock macOS disables the builtin in /etc/zshrc.
    { zshenv.content = "unsetopt GLOBAL_RCS"; }
  ];
  systemLogShell = shell.wrap { preferSystemLog.enable = true; };
in
runCommand "test-zsh-prefer-system-log" { } ''
  export HOME="$PWD/home"
  mkdir "$HOME"
  export PATH=/usr/bin:/bin
  ${shell}/bin/zsh -ic '[[ $(whence -w log) == "log: builtin" ]]'
  ${systemLogShell}/bin/zsh -ic '[[ $(whence log) == /usr/bin/log ]]'
  touch "$out"
''
