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
  allowedReferences = [ ];
  allowedRequisites = [ ];

  outputHash = "sha256-7JJhlHh3vjnvnD/h7o/KUTKL66yo02f0svG4DWcBUU8=";
  outputHashAlgo = "sha256";
  outputHashMode = "nar";

  meta = {
    description = "rclone config for Tailscale Taildrive";
    platforms = lib.platforms.all;
  };
}
