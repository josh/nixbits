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
    description = "Rclone config for Tailscale Taildrive";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
