{
  config,
  lib,
  ...
}:
let
  cfg = config.nix.trimSystemProfile;
in
{
  options.nix.trimSystemProfile = {
    enable = lib.options.mkEnableOption "trimming the system profile to the newest N generations when a generation is created";

    keep = lib.options.mkOption {
      type = lib.types.ints.positive;
      default = 10;
      description = "Number of most recent system-profile generations to keep.";
    };
  };

  config = lib.modules.mkIf cfg.enable {
    systemd.paths.nix-trim-system-profile = {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = "/nix/var/nix/profiles/system";
    };

    systemd.services.nix-trim-system-profile = {
      description = "Trim system profile to the newest ${toString cfg.keep} generations";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${config.nix.package}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +${toString cfg.keep}";
      };
    };
  };
}
