{ stdenvNoCC, nixbits }:
stdenvNoCC.mkDerivation {
  name = "git-xdg-config-home";

  buildCommand = ''
    mkdir -p $out/git
    ln -s ${nixbits.git-config} $out/git/config
    ln -s ${nixbits.gitignore} $out/git/ignore
    # touch $out/git/attributes
  '';

  meta.description = "$XDG_CONFIG_HOME for git config";
}
