{
  system,
  lib,
  writeShellScript,
  coreutils,
  nixbits,
  runCommand,
  diffoscopeMinimal,
}:
derivation {
  name = "launchd-exec";
  system = "aarch64-darwin";

  builder = writeShellScript "launchd-exec-builder" ''
    ${coreutils}/bin/install -D ${./launchd-exec} $out/bin/launchd-exec
  '';

  allowedReferences = [ ];
  allowedRequisites = [ ];

  outputHash = "sha256-CX8BosUndLeV/IzuJSmVlO0hgvbOlYWvT9YNMvQ6sfA=";
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
}
// {
  meta = {
    name = "launchd-exec-bin";
    description = "launchd exec permissions wrapper";
    mainProgram = "launchd-exec";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = lib.sourceTypes.binaryNativeCode;
    available = system == "aarch64-darwin";
  };

  tests.deterministic-binary =
    runCommand "deterministic-binary"
      {
        compiled = "${nixbits.launchd-exec}/bin/launchd-exec";
        binary = "${nixbits.launchd-exec-bin}/bin/launchd-exec";
        nativeBuildInputs = [ diffoscopeMinimal ];
      }
      ''
        if ! diffoscope --no-progress --text-color=always -- "$compiled" "$binary"; then
          echo "+: compiled: $compiled"
          echo "-: binary:   $binary"
          exit 1
        else
          touch "$out"
        fi
      '';
}
