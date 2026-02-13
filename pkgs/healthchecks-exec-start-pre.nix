{
  stdenvNoCC,
  bash,
  curl,
  systemd,
}:
stdenvNoCC.mkDerivation {
  name = "healthchecks-exec-start-pre";

  __structuredAttrs = true;

  inherit bash curl;
  pingURL = "https://hc-ping.com";
  pingKey = "";
  slug = "";

  buildCommand = ''
    ( echo "#!${bash}/bin/bash" ; cat "${./healthchecks-exec-start-pre.bash}" ) >$out
    substituteInPlace "$out" \
      --replace-fail '@curl@' "$curl" \
      --replace-fail '@pingURL@' "$pingURL" \
      --replace-fail '@pingKey@' "$pingKey" \
      --replace-fail '@slug@' "$slug"
    chmod +x "$out"
  '';

  meta = {
    description = "systemd ExecPreStart script for Healthchecks.io";
    inherit (systemd.meta) platforms;
  };
}
