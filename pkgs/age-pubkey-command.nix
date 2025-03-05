{
  stdenvNoCC,
  runtimeShell,
  writeShellScript,
  coreutils,
  nixbits,
  age-pubkey-file ? nixbits.age-pubkey-file,
}:
let
  script = writeShellScript "age-pubkey-command" ''
    if [ ! -s ${age-pubkey-file} ]; then
      echo "No age pubkey configured" >&2
      exit 1
    fi
    exec ${coreutils}/bin/cat ${age-pubkey-file}
  '';
in
stdenvNoCC.mkDerivation {
  __structuredAttrs = true;

  name = "age-pubkey-command";

  buildCommand = ''
    mkdir -p $out/bin
    install -m 755 ${script} $out/bin/age-pubkey-command

    (
      echo "#!${runtimeShell} -e"
      echo "$out/bin/$name >/dev/null"
    ) > preinstallHook.sh
    mkdir -p $out/share/nix/hooks/pre-install.d
    install -m 755 preinstallHook.sh $out/share/nix/hooks/pre-install.d/$name
  '';

  meta = {
    description = "Print system age pubkey";
    longDescription = ''
      Overloadable stub that reads `nixbits.age-pubkey-file`.
    '';
    mainProgram = "age-pubkey-command";
  };
}
