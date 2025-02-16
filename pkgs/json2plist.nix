{
  lib,
  writeShellApplication,
  runCommand,
  coreutils,
  xcbuild,
}:
let
  json2plist = writeShellApplication {
    name = "json2plist";
    runtimeEnv = {
      PATH = lib.strings.makeBinPath [
        coreutils
        xcbuild
      ];
    };
    text = ''
      exec plutil -convert xml1 -o - -- -
    '';
    meta = {
      description = "Convert a JSON file to a plist file.";
      platforms = lib.platforms.darwin;
    };
  };
in
json2plist.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        json2plist = finalAttrs.finalPackage;
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
          runCommand "test-json2plist-convert-file"
            {
              nativeBuildInputs = [ json2plist ];
            }
            ''
              expected="$(<${plistFile})"
              actual="$(json2plist <${jsonFile})"
              if [[ "$actual" != "$expected" ]]; then
                echo "expected, '$expected' but was '$actual'"
                return 1
              fi
              touch $out
            '';

        convert-pipe =
          runCommand "test-json2plist-convert-pipe"
            {
              nativeBuildInputs = [ json2plist ];
            }
            ''
              expected="$(<${plistFile})"
              actual="$(cat ${jsonFile} | json2plist)"
              if [[ "$actual" != "$expected" ]]; then
                echo "expected, '$expected' but was '$actual'"
                return 1
              fi
              touch $out
            '';
      };
  }
)
