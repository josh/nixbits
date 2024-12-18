{ formats }:
let
  ini = formats.ini {
    mkKeyValue = key: value: "${key} = ${value}";
  };
in
ini.generate "rclone.conf" {
  taildrive = {
    type = "webdav";
    url = "http://100.100.100.100:8080";
    vendor = "other";
  };
}
