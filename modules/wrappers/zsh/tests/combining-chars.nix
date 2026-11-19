{ runCommand, wlibEvalPackage }:
let
  shell = wlibEvalPackage [
    ../../zsh.nix
    {
      combiningChars.enable = true;
      # Stock macOS also sets COMBINING_CHARS in /etc/zshrc.
      zshenv.content = "unsetopt GLOBAL_RCS";
    }
  ];
in
runCommand "test-zsh-combining-chars" { } ''
  export HOME="$PWD/home"
  mkdir "$HOME"
  LC_ALL=en_US.UTF-8 ${shell}/bin/zsh +o combiningchars -ic '[[ -o combiningchars ]]'
  LC_ALL=C ${shell}/bin/zsh +o combiningchars -ic '[[ ! -o combiningchars ]]'
  LC_ALL=C ${shell}/bin/zsh -o combiningchars -ic '[[ -o combiningchars ]]'
  touch "$out"
''
