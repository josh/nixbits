{
  runCommand,
  jq,
  checkPkg,
}:
runCommand "${checkPkg.name}-references-check"
  {
    inherit checkPkg;
    __structuredAttrs = true;
    allowedReferencesCount =
      if (checkPkg ? allowedReferences) then (builtins.length checkPkg.allowedReferences) else -1;
    allowedRequisitesCount =
      if (checkPkg ? allowedRequisites) then (builtins.length checkPkg.allowedRequisites) else -1;
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
      '.allowedReferencesCount' \
      "$NIX_ATTRS_JSON_FILE"
    );
    allowedReqcount=$(jq \
      --raw-output \
      '.allowedRequisitesCount' \
      "$NIX_ATTRS_JSON_FILE"
    );

    if [ "$refcount" -eq 0 ] && [ "$allowedRefcount" -ne 0 ]; then
      echo "error: ${checkPkg.name} has no references, it should add 'allowedReferences = [ ];'" >&2
      exit 1
    fi
    if [ "$refcount" -eq 0 ] && [ "$allowedReqcount" -ne 0 ]; then
      echo "error: ${checkPkg.name} has no references, it should add 'allowedRequisites = [ ];'" >&2
      exit 1
    fi

    touch $out
  ''
