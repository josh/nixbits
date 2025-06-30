{
  lib,
  stdenvNoCC,
  jq,
  remarshal,
}:
stdenvNoCC.mkDerivation {
  name = "gh-config-dir";

  __structuredAttrs = true;

  nativeBuildInputs = [
    jq
    remarshal
  ];

  ghConfig = {
    version = 1;
    git_protocol = "https";
    editor = "";
    prompt = "enabled";
    prefer_editor_prompt = "disabled";
    pager = "";
  };

  ghHosts = {
    "github.com" = {
      git_protocol = "https";
      users.josh = "";
      user = "josh";
    };
  };

  buildCommand = ''
    mkdir $out
    jq '.ghConfig' <"$NIX_ATTRS_JSON_FILE" | json2yaml >$out/config.yml
    jq '.ghHosts' <"$NIX_ATTRS_JSON_FILE" | json2yaml >$out/hosts.yml
  '';

  meta = {
    description = "Static GitHub CLI configuration directory";
    # BUG: Only works on macOS as linux expects this directory to be writable
    platforms = lib.platforms.darwin;
  };
}
