{
  config,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.wrapperModules.starship ];

  wrapperImplementation = "binary";

  settings = {
    git_branch.disabled = true;
    git_commit.disabled = true;
    git_state.disabled = true;
    git_status.disabled = true;

    custom.jj = {
      description = "Current jj change / bookmarks";
      when = "${pkgs.jujutsu}/bin/jj root --ignore-working-copy";
      symbol = " ";
      style = "bold purple";
      format = "on [$symbol]($style)$output ";
      command = "${pkgs.nixbits.starship-jj-command}/bin/starship-jj-command";
    };
  };

  passthru.tests = {
    version = pkgs.testers.testVersion {
      package = config.wrapper;
      command = "starship --version";
      inherit (config.wrapper) version;
    };

    jj = pkgs.runCommand "test-starship-jj" { nativeBuildInputs = [ config.wrapper ]; } ''
      export HOME="$PWD"
      ${pkgs.jujutsu}/bin/jj git init repo
      cd repo
      ${pkgs.jujutsu}/bin/jj describe --message nixbits-starship-test
      actual="$(starship module custom.jj)"
      if [[ "$actual" != *nixbits-starship-test* ]]; then
        echo "expected jj description in prompt, but was '$actual'"
        return 1
      fi
      touch $out
    '';
  };
}
