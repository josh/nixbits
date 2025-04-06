{
  lib,
  stdenv,
  runCommand,
}:
stdenv.mkDerivation (finalAttrs: {
  name = "ensure-newline";
  src = ./ensure-newline.c;

  buildCommand = ''
    mkdir -p $out/bin
    clang ${./ensure-newline.c} -o $out/bin/ensure-newline
  '';

  passthru.tests =
    let
      ensure-newline = finalAttrs.finalPackage;
      runTest =
        {
          name,
          input,
          output,
        }:
        runCommand name
          {
            __structureAttrs = true;
            nativeBuildInputs = [ ensure-newline ];
            inherit input;
            expected = output;
          }
          ''
            printf "$expected" >expected.txt
            printf "$input" | ensure-newline >actual.txt
            if ! diff --text --unified expected.txt actual.txt >diff.txt; then
              echo "Files differ, showing diff:"
              cat diff.txt
              return 1
            fi
            touch $out
          '';
    in
    {
      noop = runTest {
        name = "test-noop";
        input = "foo\n";
        output = "foo\n";
      };

      add = runTest {
        name = "test-add";
        input = "foo";
        output = "foo\n";
      };

      multiline-noop = runTest {
        name = "test-multiline-noop";
        input = "foo\nbar\nbar\n";
        output = "foo\nbar\nbar\n";
      };

      multiline-add = runTest {
        name = "test-multiline-add";
        input = "foo\nbar\nbar";
        output = "foo\nbar\nbar\n";
      };
    };

  meta = {
    description = "Ensures stdout ends with trailing newline";
    platforms = lib.platforms.all;
    mainProgram = "ensure-newline";
  };
})
