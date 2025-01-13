{
  runCommand,
  jq,
  checkPkg,
}:
runCommand "${checkPkg.name}-references-check"
  {
    inherit checkPkg;
    __structuredAttrs = true;
    checkPkgAttrs = {
      allowedReferences = checkPkg.allowedReferences or null;
      allowedRequisites = checkPkg.allowedRequisites or null;
      outputHash = checkPkg.outputHash or null;
    };
    exportReferencesGraph.closure = checkPkg;
    nativeBuildInputs = [ jq ];
  }
  ''
    refcount=$(jq \
      --raw-output \
      --arg path "${checkPkg}" \
      '.closure[] | select(.path == $path) | .references | length' \
      "$NIX_ATTRS_JSON_FILE"
    );

    allowedRefcount=$(jq \
      --raw-output \
      '.checkPkgAttrs.allowedReferences | if . == null then -1 else length end' \
      "$NIX_ATTRS_JSON_FILE"
    );
    allowedReqcount=$(jq \
      --raw-output \
      '.checkPkgAttrs.allowedRequisites | if . == null then -1 else length end' \
      "$NIX_ATTRS_JSON_FILE"
    );
    outputHash=$(jq \
      --raw-output \
      '.checkPkgAttrs.outputHash' \
      "$NIX_ATTRS_JSON_FILE"
    );

    if [ "$refcount" -eq 0 ]; then
      if [ "$allowedRefcount" -ne 0 ]; then
        echo "error: ${checkPkg.name} has no references, it should add 'allowedReferences = [ ];'" >&2
        exit 1
      fi
      if [ "$allowedReqcount" -ne 0 ]; then
        echo "error: ${checkPkg.name} has no references, it should add 'allowedRequisites = [ ];'" >&2
        exit 1
      fi
      if [ "$outputHash" == "null" ]; then
        echo "error: ${checkPkg.name} has no references, it should be a fixed-output derivation" >&2
        exit 1
      fi
    fi

    (
      echo "refcount: $refcount" ;
      echo "allowedRefcount: $allowedRefcount" ;
      echo "allowedReqcount: $allowedReqcount" ;
      echo "outputHash: $outputHash"
    ) >$out
  ''
