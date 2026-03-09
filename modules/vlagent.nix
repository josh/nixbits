{ config, lib, ... }:
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
      systemd.coredump.extraConfig = ''
        Storage=journal
      '';
    })
  ];
}
