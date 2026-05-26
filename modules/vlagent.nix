{
  config,
  lib,
  options,
  ...
}:
{
  config = lib.modules.mkMerge [
    {
      services.vlagent.enable = lib.modules.mkDefault config.services.vlagent.remoteWrite.url != null;
      services.vlagent.extraArgs = [ "-httpListenAddr=127.0.0.1:9429" ];
      services.journald.upload.enable = lib.modules.mkDefault config.services.vlagent.enable;
    }
    (lib.modules.mkIf config.services.vlagent.enable {
      services.journald.upload.settings.Upload.URL = "http://localhost:9429/insert/journald";
      services.journald.storage = "volatile";
      services.journald.extraConfig = ''
        MaxRetentionSec=1d
      '';
    })
    # Support both NixOS 25.11 and 26.05
    # https://github.com/NixOS/nixpkgs/commit/ab076fc22ddb751249a518de8b3217e1097bcb82
    (lib.modules.mkIf config.services.vlagent.enable (
      if options.systemd.coredump ? settings then
        {
          systemd.coredump.settings.Coredump.Storage = "journal";
        }
      else
        {
          systemd.coredump.extraConfig = ''
            Storage=journal
          '';
        }
    ))
  ];
}
