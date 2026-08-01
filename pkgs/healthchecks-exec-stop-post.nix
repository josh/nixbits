{
  lib,
  stdenvNoCC,
  bash,
  curl,
  systemd,
}:
stdenvNoCC.mkDerivation {
  name = "healthchecks-exec-stop-post";

  __structuredAttrs = true;

  inherit bash curl systemd;
  pingURL = "https://hc-ping.com";
  pingKey = "";
  slug = "";

  buildCommand = ''
    ( echo "#!${bash}/bin/bash" ; cat "${./healthchecks-exec-stop-post.bash}" ) >$out
    substituteInPlace "$out" \
      --replace-fail '@curl@' "$curl" \
      --replace-fail '@systemd@' "$systemd" \
      --replace-fail '@pingURL@' "$pingURL" \
      --replace-fail '@pingKey@' "$pingKey" \
      --replace-fail '@slug@' "$slug"
    chmod +x "$out"
  '';

  meta = {
    description = "Systemd ExecStopPost script for Healthchecks.io";
    license = lib.licenses.mit;
    inherit (systemd.meta) platforms;
  };
}
