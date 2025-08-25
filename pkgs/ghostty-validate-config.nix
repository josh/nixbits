{
  lib,
  stdenv,
  writeShellApplication,
  ghostty,
}:
let
  darwinScript = writeShellApplication {
    name = "ghostty-validate-config";
    text = builtins.readFile ./ghostty-validate-config-darwin.bash;
    inheritPath = false;
    meta = {
      description = "Validate Ghostty configuration";
      platforms = lib.platforms.darwin;
    };
  };

  linuxScript = writeShellApplication {
    name = "ghostty-validate-config";
    text = builtins.readFile ./ghostty-validate-config-linux.bash;
    runtimeInputs = [ ghostty ];
    inheritPath = false;
    meta = {
      description = "Validate Ghostty configuration";
      platforms = lib.platforms.linux;
    };
  };
in
if stdenv.hostPlatform.isDarwin then darwinScript else linuxScript
