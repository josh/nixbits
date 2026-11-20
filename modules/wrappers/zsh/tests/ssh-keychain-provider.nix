{ runCommand, wlibEvalPackage }:
let
  shell = wlibEvalPackage [
    ../../zsh.nix
    { zshenv.content = "unsetopt GLOBAL_RCS"; }
  ];
  providerShell = shell.wrap { sshKeychainProvider.enable = true; };
in
runCommand "test-zsh-ssh-keychain-provider" { } ''
  export HOME="$PWD/home"
  mkdir "$HOME"
  unset SSH_SK_PROVIDER
  ${shell}/bin/zsh -ic '[[ -z ''${SSH_SK_PROVIDER:-} ]]'
  ${providerShell}/bin/zsh -ic '[[ $SSH_SK_PROVIDER == /usr/lib/ssh-keychain.dylib ]]'
  SSH_SK_PROVIDER=/custom.dylib ${providerShell}/bin/zsh -ic '[[ $SSH_SK_PROVIDER == /custom.dylib ]]'
  touch "$out"
''
