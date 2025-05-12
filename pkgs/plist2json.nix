{
  lib,
  writeShellApplication,
  runCommand,
  coreutils,
  jq,
  xcbuild,
}:
let
  plist2json = writeShellApplication {
    name = "plist2json";
    runtimeInputs = [
      coreutils
      xcbuild
    ];
    inheritPath = false;
    text = ''
      exec plutil -convert json -o - -- -
    '';
    meta = {
      description = "Convert a plist file to a JSON file.";
      platforms = lib.platforms.darwin;
    };
  };
in
plist2json.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        plist2json = finalAttrs.finalPackage;
        jsonFile = builtins.toFile "foo.json" ''
          {"foo":"bar"}
        '';
        plistFile = builtins.toFile "foo.plist" ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
          	<key>foo</key>
          	<string>bar</string>
          </dict>
          </plist>
        '';
      in
      {
        convert-file =
          runCommand "test-plist2json-convert-file"
            {
              nativeBuildInputs = [
                plist2json
                jq
              ];
            }
            ''
              expected="$(<${jsonFile})"
              actual="$(plist2json <${plistFile} | jq --compact-output)"
              if [[ "$actual" != "$expected" ]]; then
                echo "expected, '$expected' but was '$actual'"
                return 1
              fi
              touch $out
            '';

        convert-pipe =
          runCommand "test-plist2json-convert-pipe"
            {
              nativeBuildInputs = [
                plist2json
                jq
              ];
            }
            ''
              expected="$(<${jsonFile})"
              actual="$(cat ${plistFile} | plist2json | jq --compact-output)"
              if [[ "$actual" != "$expected" ]]; then
                echo "expected, '$expected' but was '$actual'"
                return 1
              fi
              touch $out
            '';
      };
  }
)
