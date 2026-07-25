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
    enable = lib.options.mkEnableOption "trimming the system profile to the newest N generations on every activation";

    keep = lib.options.mkOption {
      type = lib.types.ints.positive;
      default = 10;
      description = "Number of most recent system-profile generations to keep.";
    };
  };

  config = lib.modules.mkIf cfg.enable {
    systemd.services.nix-trim-system-profile = {
      description = "Trim system profile to the newest ${toString cfg.keep} generations";
      wantedBy = [ "sysinit.target" ];
      requiredBy = [ "sysinit-reactivation.target" ];
      after = [ "local-fs.target" ];
      before = [
        "sysinit.target"
        "sysinit-reactivation.target"
        "shutdown.target"
      ];
      conflicts = [ "shutdown.target" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${config.nix.package}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +${toString cfg.keep}";
      };
    };
  };
}
