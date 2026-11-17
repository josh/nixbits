{
  git,
  lib,
  nixbits,
  runCommand,
}:
runCommand "test-git-credential-helpers" { nativeBuildInputs = [ git ]; } ''
  expected="${lib.getExe nixbits.gh} auth git-credential"
  printf '%s\n' "" "$expected" >expected
  for url in https://github.com https://gist.github.com; do
    git config get --all "credential.$url.helper" >actual
    cmp expected actual
  done
  touch $out
''
