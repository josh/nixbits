{
  system,
  lib,
  writeShellScript,
  coreutils,
  llvmPackages_19,
}:
derivation {
  system = "aarch64-darwin";
  name = "launchd-exec";
  builder = writeShellScript "launchd-exec-builder" ''
    ${llvmPackages_19.clang}/bin/clang ${./launchd-exec.c} -o launchd-exec
    ${coreutils}/bin/install -D launchd-exec $out/bin/launchd-exec
  '';
  allowedReferences = [ ];
  allowedRequisites = [ ];

  outputHash = "sha256-CX8BosUndLeV/IzuJSmVlO0hgvbOlYWvT9YNMvQ6sfA=";
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
}
// {
  meta = {
    description = "launchd exec permissions wrapper";
    mainProgram = "launchd-exec";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = lib.sourceTypes.fromSource;
    available = system == "aarch64-darwin";
  };
}
