{ lib, formats }:
let
  ini = formats.ini {
    mkKeyValue = key: value: "${key} = ${value}";
  };
  config = ini.generate "rclone.conf" {
    taildrive = {
      type = "webdav";
      url = "http://100.100.100.100:8080";
      vendor = "other";
    };
  };
  meta = config.meta // {
    description = "rclone config for Tailscale Taildrive";
    platforms = lib.platforms.all;
  };
in
config // { inherit meta; }
