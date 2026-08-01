{
  config,
  lib,
  pkgs,
  ...
}:
let
  runitor-wrapper = pkgs.callPackage ../pkgs/runitor-wrapper.nix { };
  healthchecks-apply = pkgs.callPackage ../pkgs/healthchecks-apply.nix { };
  healthchecks-exec-start-pre = pkgs.callPackage ../pkgs/healthchecks-exec-start-pre.nix { };
  healthchecks-exec-stop-post = pkgs.callPackage ../pkgs/healthchecks-exec-stop-post.nix { };

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
      enable = lib.options.mkEnableOption "healthchecks sync";

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
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Healthchecks read-write API key";
      };

      apiKeyFile = lib.options.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to a file containing the read-write API key, read at runtime";
      };

      apiKeyCommand = lib.options.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Command printing the read-write API key on stdout, run at runtime";
      };

      pingKey = lib.options.mkOption {
        type = lib.types.str;
        description = "Healthchecks ping API key";
      };

      activationPackage = lib.options.mkOption {
        type = lib.types.package;
        description = "healthchecks-apply package used to sync checks to the server";
        default = healthchecks-apply.override {
          healthchecksConfig = {
            checksPath = pkgs.writers.writeJSON "healthchecks.json" cfg.checks;
            apiURL = cfg.url;
            delete = true;
          }
          // (lib.attrsets.optionalAttrs (cfg.apiKey != null) { inherit (cfg) apiKey; })
          // (lib.attrsets.optionalAttrs (cfg.apiKeyFile != null) { inherit (cfg) apiKeyFile; })
          // (lib.attrsets.optionalAttrs (cfg.apiKeyCommand != null) { inherit (cfg) apiKeyCommand; });
        };
      };

      runitor = lib.options.mkOption {
        type = lib.types.package;
        description = "runitor wrapped with this module's ping URL and key";
        default = runitor-wrapper.overrideAttrs {
          makeWrapperArgs = [
            "--set"
            "HC_API_URL"
            cfg.pingURL
          ]
          ++ [
            "--set"
            "HC_PING_KEY"
            cfg.pingKey
          ];
        };
      };

      execStartPre = lib.options.mkOption {
        type = lib.types.package;
        description = "Script for systemd ExecStartPre that pings the check start endpoint";
        default = healthchecks-exec-start-pre.overrideAttrs {
          inherit (cfg) pingURL pingKey;
        };
      };

      execStopPost = lib.options.mkOption {
        type = lib.types.package;
        description = "Script for systemd ExecStopPost that pings the check status endpoint";
        default = healthchecks-exec-stop-post.overrideAttrs {
          inherit (cfg) pingURL pingKey;
        };
      };

      checks = lib.options.mkOption {
        type = lib.types.listOf checkType;
        default = [ ];
        description = "Checks to sync to the healthchecks server";
      };
    };
  };

  config = lib.modules.mkIf cfg.enable {
    assertions =
      let
        slugCounts = lib.lists.foldl' (
          counts: check: counts // { ${check.slug} = (counts.${check.slug} or 0) + 1; }
        ) { } cfg.checks;
        duplicateSlugs = builtins.attrNames (lib.attrsets.filterAttrs (_slug: count: count > 1) slugCounts);
        apiKeySources = builtins.filter (source: source != null) [
          cfg.apiKey
          cfg.apiKeyFile
          cfg.apiKeyCommand
        ];
      in
      [
        {
          assertion = builtins.length apiKeySources <= 1;
          message = "healthchecks: only one of apiKey, apiKeyFile or apiKeyCommand may be set";
        }
        {
          assertion = duplicateSlugs == [ ];
          message = "healthchecks.checks contains duplicate slugs: ${builtins.concatStringsSep ", " duplicateSlugs}";
        }
      ];

    systemd.services.healthchecks-apply = {
      description = "Sync healthchecks.io checks";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      restartTriggers = [ cfg.activationPackage ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = lib.getExe cfg.activationPackage;
      };
    };
  };
}
