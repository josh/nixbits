{
  lib,
  writeShellApplication,
  nixbits,
  jjConfiguration ? nixbits.jujutsu.configuration,
}:
writeShellApplication {
  name = "jj-new-main";
  runtimeInputs = [
    (nixbits.jujutsu-new-trunk.override { inherit jjConfiguration; })
  ];
  inheritPath = false;
  text = ''
    echo "jj-new-main is deprecated; use jj-new-trunk" >&2
    exec jj-new-trunk "$@"
  '';

  meta = {
    description = "Deprecated alias for jj-new-trunk";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
