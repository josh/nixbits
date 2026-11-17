{
  config,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.modules.default ];

  package = pkgs.wget;
  wrapperImplementation = "nix";
  escapingFunction = wlib.escapeShellArgWithEnv;

  flagSeparator = "=";
  flags."--hsts-file" = "\${XDG_DATA_HOME:-$HOME/.local/share}/wget-hsts";

  passthru.tests = {
    version = pkgs.testers.testVersion {
      package = config.wrapper;
      command = "wget --version";
      inherit (config.wrapper) version;
    };

    hsts-file = pkgs.runCommand "test-wget-hsts-file" { } ''
      if ! grep --quiet '"--hsts-file=''${XDG_DATA_HOME' ${config.wrapper}/bin/wget; then
        echo "expected the hsts path to expand at runtime, but wrapper was:"
        cat ${config.wrapper}/bin/wget
        return 1
      fi
      touch $out
    '';
  };
}
