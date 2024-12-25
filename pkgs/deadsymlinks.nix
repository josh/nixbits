{
  lib,
  writeShellApplication,
  runCommand,
  findutils,
  testers,
}:
let
  deadsymlinks = writeShellApplication {
    name = "deadsymlinks";
    runtimeEnv = {
      PATH = lib.strings.makeBinPath [
        findutils
      ];
    };
    text = ''
      find . -xtype l
    '';

    passthru.tests = {
      usage = testers.testEqualContents {
        assertion = "deadsymlinks works";
        expected = runCommand "expected" { } ''
          echo "./bar-symlink" >$out
        '';
        actual = runCommand "actual" { nativeBuildInputs = [ deadsymlinks ]; } ''
          echo 42 >foo
          echo 42 >bar
          ln -s foo foo-symlink
          ln -s bar bar-symlink
          rm bar

          deadsymlinks >$out
        '';
      };
    };
  };
in
deadsymlinks
