{
  config,
  lib,
  ...
}:
{
  config = {
    services.vmagent.enable = lib.modules.mkDefault config.services.vmagent.remoteWrite.url != null;

    services.vmagent.prometheusConfig.scrape_configs =
      # https://docs.victoriametrics.com/victoriametrics/vmagent/#monitoring
      (lib.lists.optional config.services.vmagent.enable {
        job_name = "vmagent";
        scrape_interval = "30s";
        static_configs = [
          { targets = [ "127.0.0.1:8429" ]; }
        ];
        # BUG: NixOS builds vmagent without program in version prefix
        # https://github.com/VictoriaMetrics/VictoriaMetrics/issues/1785
        metric_relabel_configs = [
          {
            source_labels = [
              "__name__"
              "version"
            ];
            regex = "vm_app_version;([0-9].*)";
            target_label = "version";
            replacement = "vmagent-$1";
          }
        ];
        relabel_configs = [
          {
            target_label = "instance";
            replacement = config.networking.hostName;
          }
        ];
      })
      # https://docs.victoriametrics.com/victorialogs/vlagent/#monitoring
      ++ (lib.lists.optional config.services.vlagent.enable {
        job_name = "vlagent";
        scrape_interval = "30s";
        static_configs = [
          { targets = [ "127.0.0.1:9429" ]; }
        ];
        # BUG: NixOS builds vlagent without program in version prefix
        # https://github.com/VictoriaMetrics/VictoriaMetrics/issues/1785
        metric_relabel_configs = [
          {
            source_labels = [
              "__name__"
              "version"
            ];
            regex = "vm_app_version;([0-9].*)";
            target_label = "version";
            replacement = "vlagent-$1";
          }
        ];
        relabel_configs = [
          {
            target_label = "instance";
            replacement = config.networking.hostName;
          }
        ];
      })
      ++ (lib.lists.optional config.services.prometheus.exporters.node.enable {
        job_name = "node";
        scrape_interval = "30s";
        static_configs = [
          { targets = [ "127.0.0.1:9100" ]; }
        ];
        relabel_configs = [
          {
            target_label = "instance";
            replacement = config.networking.hostName;
          }
        ];
      })
      # https://tailscale.com/docs/reference/tailscale-client-metrics
      ++ (lib.lists.optional config.services.tailscale.enable {
        job_name = "tailscale";
        scrape_interval = "30s";
        static_configs = [
          { targets = [ "100.100.100.100" ]; }
        ];
        relabel_configs = [
          {
            target_label = "instance";
            replacement = config.networking.hostName;
          }
        ];
      });

    services.prometheus.exporters.node = {
      enable = lib.modules.mkDefault config.services.vmagent.enable;
      enabledCollectors = [ "systemd" ];
    };
  };
}
