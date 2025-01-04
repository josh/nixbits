# Fork of <https://github.com/NixOS/nixpkgs/blob/5f1d105/pkgs/os-specific/darwin/impure-cmds/default.nix>
{
  lib,
  runCommandLocal,
  name ? (builtins.baseNameOf command),
  command ? "/bin/sh",
}:
runCommandLocal "${name}-impure-darwin"
  {
    __impureHostDeps = [ command ];

    meta = {
      platforms = lib.platforms.darwin;
    };
  }
  ''
    if ! [ -x ${command} ]; then
      echo Cannot find command ${command}
      exit 1
    fi

    mkdir -p $out/bin
    ln -s ${command} $out/bin

    manpage="/usr/share/man/man1/${name}.1"
    if [ -f $manpage ]; then
      mkdir -p $out/share/man/man1
      ln -s $manpage $out/share/man/man1
    fi
  ''
