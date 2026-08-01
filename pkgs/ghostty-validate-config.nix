{
  lib,
  stdenv,
  writeShellApplication,
  ghostty,
}:
let
  darwin-script = writeShellApplication {
    name = "ghostty-validate-config";
    inheritPath = false;
    text = builtins.readFile ./ghostty-validate-config-darwin.bash;
    meta = {
      description = "Validate Ghostty configuration";
      license = lib.licenses.mit;
      platforms = lib.platforms.darwin;
    };
  };

  linux-script = writeShellApplication {
    name = "ghostty-validate-config";
    runtimeInputs = [ ghostty ];
    inheritPath = false;
    text = builtins.readFile ./ghostty-validate-config-linux.bash;
    meta = {
      description = "Validate Ghostty configuration";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
    };
  };
in
if stdenv.hostPlatform.isDarwin then darwin-script else linux-script
