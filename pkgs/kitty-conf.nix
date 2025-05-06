{
  lib,
  stdenvNoCC,
  nur,
}:
let
  inherit (nur.repos.josh) rose-pine-kitty;

  theme = "${rose-pine-kitty}/share/kitty/rose-pine.conf";
in
stdenvNoCC.mkDerivation {
  name = "kitty-conf";

  __structuredAttrs = true;

  theme = "rosepine";

  buildCommand = ''
    substitute ${./kitty.conf} kitty.conf \
      --replace-fail '@theme@' "$theme"

    (
      echo "# BEGIN_KITTY_THEME"
      cat ${theme}
      echo "# END_KITTY_THEME"
      echo ""
      cat kitty.conf
    ) >$out
  '';

  meta = {
    description = "Kitty config";
    platforms = lib.platforms.all;
  };
}
