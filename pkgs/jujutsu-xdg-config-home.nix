{ stdenvNoCC, nixbits }:
stdenvNoCC.mkDerivation {
  name = "jujutsu-xdg-config-home";

  buildCommand = ''
    mkdir -p $out/jj $out/git
    ln -s ${nixbits.jujutsu-config} $out/jj/config.toml
    ln -s ${nixbits.git-config} $out/git/config
    ln -s ${nixbits.gitignore} $out/git/ignore
  '';

  meta.description = "$XDG_CONFIG_HOME for jujutsu config";
}
