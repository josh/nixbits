{
  config,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.modules.default ];

  package = pkgs.eza;
  wrapperImplementation = "binary";

  flags."--group-directories-first" = true;

  drv.meta.description = "Modern ls replacement listing directories first";

  passthru.tests = {
    version = pkgs.testers.testVersion {
      package = config.wrapper;
      command = "eza --version";
      version = "v${config.wrapper.version}";
    };

    directories-first =
      pkgs.runCommand "test-eza-directories-first" { nativeBuildInputs = [ config.wrapper ]; }
        ''
          mkdir listing listing/b
          touch listing/a
          actual="$(eza --oneline --color=never listing | tr '\n' ' ')"
          if [[ "$actual" != "b a " ]]; then
            echo "expected 'b a ' but was '$actual'"
            return 1
          fi
          touch $out
        '';
  };
}
