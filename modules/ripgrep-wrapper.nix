{
  config,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.wrapperModules.ripgrep ];

  wrapperImplementation = "binary";

  settings = {
    smart-case = true;
    max-columns = 200;
    max-columns-preview = true;
  };

  passthru.tests = {
    version = pkgs.testers.testVersion {
      package = config.wrapper;
      command = "rg --version";
      inherit (config.wrapper) version;
    };

    smart-case =
      pkgs.runCommand "test-ripgrep-smart-case" { nativeBuildInputs = [ config.wrapper ]; }
        ''
          echo "Hello World" >input
          if ! rg --quiet hello input; then
            echo "expected lowercase pattern to match case-insensitively"
            return 1
          fi
          if rg --quiet Hello-world input; then
            echo "expected mixed-case pattern to stay case-sensitive"
            return 1
          fi
          touch $out
        '';
  };
}
