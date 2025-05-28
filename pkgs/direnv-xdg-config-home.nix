{
  lib,
  stdenvNoCC,
  writers,
  uv,
}:
let
  config = writers.writeTOML "direnv.toml" {
    strict_env = true;
    whitelist.prefix = lib.lists.optionals stdenvNoCC.hostPlatform.isDarwin [
      "/Users/josh/Developer"
    ];
  };
in
stdenvNoCC.mkDerivation {
  name = "direnv-xdg-config-home";

  buildCommand = ''
    mkdir -p $out/direnv
    cp ${config} $out/direnv/direnv.toml
    substitute ${./direnvrc.bash} $out/direnv/direnvrc \
      --replace-fail "@uv@" "${lib.getExe uv}"
  '';

  meta.description = "$XDG_CONFIG_HOME for direnv";
}
