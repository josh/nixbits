{
  config,
  lib,
  pkgs,
  wlib,
  ...
}:
let
  configDir = pkgs.nixbits.zellij-config.override { inherit (config) zellijTheme; };
in
{
  imports = [ wlib.modules.default ];

  options.zellijTheme = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = ''
      Zellij theme name, passed through to `nixbits.zellij-config`.
    '';
  };

  config = {
    package = pkgs.zellij;
    wrapperImplementation = "binary";

    env.ZELLIJ_CONFIG_DIR = configDir;

    passthru.tests = {
      version = pkgs.testers.testVersion {
        package = config.wrapper;
        command = "zellij --version";
        inherit (config.wrapper) version;
      };

      config-dir = pkgs.runCommand "test-zellij-config-dir" { nativeBuildInputs = [ config.wrapper ]; } ''
        export HOME="$PWD"
        actual="$(zellij setup --check 2>&1 || true)"
        if [[ "$actual" != *'${configDir}/config.kdl'* ]]; then
          echo "expected ${configDir}/config.kdl in setup --check, but was:"
          echo "$actual"
          return 1
        fi
        touch $out
      '';
    };
  };
}
