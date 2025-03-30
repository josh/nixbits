{
  stdenvNoCC,
  runtimeShell,
  writeShellScript,
}:
let
  script = writeShellScript "age-pubkey-command" ''
    echo "No age pubkey configured" >&2
    exit 1
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
    mainProgram = "age-pubkey-command";
  };
}
