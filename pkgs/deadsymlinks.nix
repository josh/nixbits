{
  writeShellApplication,
  writeText,
  runCommand,
  findutils,
  testers,
}:
let
  deadsymlinks = writeShellApplication {
    name = "deadsymlinks";
    runtimeInputs = [ findutils ];
    text = builtins.readFile ./deadsymlinks.bash;

    passthru.tests = {
      usage = testers.testEqualContents {
        assertion = "deadsymlinks works";
        expected = writeText "expected" ''
          ./bar-symlink
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
