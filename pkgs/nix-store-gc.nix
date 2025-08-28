{
  lib,
  stdenvNoCC,
  runtimeShell,
  shellcheck-minimal,
  nix,
  nixbits,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "nix-store-gc";

  __structuredAttrs = true;

  runtimePath = [
    nix
    nixbits.nix-store-usage
  ];

  nixStoreGCMax = 100 * 1024 * 1024 * 1024; # 100GB
  nixProfileWipeHistoryOlderThan = "7d";

  text = ''
    #!${runtimeShell}
    set -o errexit
    set -o nounset
    set -o pipefail

    export PATH="${lib.strings.makeBinPath finalAttrs.runtimePath}"

    # shellcheck source=/dev/null
    source "${nixbits.xtrace}/share/bash/xtrace.bash"

    NIX_STORE_GC_MAX=${builtins.toString finalAttrs.nixStoreGCMax}
    NIX_PROFILE_WIPE_HISTORY_OLDER_THAN=${finalAttrs.nixProfileWipeHistoryOlderThan}

    ${builtins.readFile ./nix-store-gc.bash}
  '';

  buildCommand = ''
    target="$out/bin/nix-store-gc"
    mkdir -p $out/bin
    echo -n "$text" >"$target"
    chmod +x "$target"

    runHook preCheck
    $SHELL -n "$target"
    ${lib.meta.getExe shellcheck-minimal} "$target"
    runHook postCheck
  '';

  meta = {
    description = "Collect Nix Store Garbage";
    platforms = lib.platforms.all;
    mainProgram = "nix-store-gc";
  };
})
