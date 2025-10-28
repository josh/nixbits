{
  config,
  lib,
  pkgs,
  ...
}:
let
  runitor-wrapper = pkgs.callPackage ../pkgs/runitor-wrapper.nix { };
  healthchecks-apply = pkgs.callPackage ../pkgs/healthchecks-apply.nix { };

  cfg = config.healthchecks;

  checkType = lib.types.submodule {
    options = {
      slug = lib.options.mkOption {
        type = lib.types.str;
        description = "Slug for the new check";
      };

      timeout = lib.options.mkOption {
        type = lib.types.int;
        description = "The expected period of this check in seconds";
      };

      grace = lib.options.mkOption {
        type = lib.types.int;
        description = "The grace period for this check in seconds";
      };
    };
  };
in
{
  options = {
    healthchecks = {
      enable = lib.options.mkEnableOption {
        description = "Enable healthchecks sync";
      };

      url = lib.options.mkOption {
        type = lib.types.str;
        default = "https://healthchecks.io";
        description = "Healthchecks URL";
      };

      pingURL = lib.options.mkOption {
        type = lib.types.str;
        default = "https://hc-ping.com";
        description = "Healthchecks ping URL";
      };

      apiKey = lib.options.mkOption {
        type = lib.types.str;
        description = "Healthchecks read-write API key";
      };

      pingKey = lib.options.mkOption {
        type = lib.types.str;
        description = "Healthchecks ping API key";
      };

      activationPackage = lib.options.mkOption {
        type = lib.types.package;
        default = healthchecks-apply.override {
          healthchecksConfig = {
            checksPath = pkgs.writers.writeJSON "healthchecks.json" cfg.checks;
            apiURL = cfg.url;
            inherit (cfg) apiKey;
            delete = true;
          };
        };
      };

      runitor = lib.options.mkOption {
        type = lib.types.package;
        default = runitor-wrapper.overrideAttrs {
          makeWrapperArgs = [
            "--set"
            "HC_API_URL"
            cfg.pingURL
          ]
          ++ [
            "--set"
            "PING_KEY"
            cfg.pingKey
          ];
        };
      };

      checks = lib.options.mkOption {
        type = lib.types.listOf checkType;
        default = [ ];
      };
    };
  };

  config = lib.modules.mkIf cfg.enable {
    system.activationScripts.healthchecks.text = ''
      if [ "$NIXOS_ACTION" = "dry-activate" ]; then
        ${lib.getExe cfg.activationPackage} --dry-run
      else
        ${lib.getExe cfg.activationPackage}
      fi
    '';
    system.activationScripts.healthchecks.supportsDryActivation = true;
  };
}
