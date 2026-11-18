{
  lib,
  runCommand,
  zoxide,
}:
runCommand "zoxide-init.zsh" { nativeBuildInputs = [ zoxide ]; } ''
  zoxide init zsh >out
  substitute out $out --replace-fail '\command zoxide' '${lib.getExe zoxide}'
''
