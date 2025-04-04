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
in
config.overrideAttrs {
  meta = {
    name = "rclone-taildrive-config";
    description = "rclone config for Tailscale Taildrive";
    platforms = lib.platforms.all;
  };
}
