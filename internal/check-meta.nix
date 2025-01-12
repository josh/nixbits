{
  runCommand,
  jq,
  checkPkg,
}:
runCommand "${checkPkg.name}-meta-check"
  {
    inherit checkPkg;
    checkPkgMeta = checkPkg.meta;
    __structuredAttrs = true;
    nativeBuildInputs = [ jq ];
  }
  ''
    jq '.checkPkgMeta' "$NIX_ATTRS_JSON_FILE" >meta.json

    description=$(jq --raw-output '.description' meta.json)
    available=$(jq --raw-output '.available' meta.json)
    platforms=$(jq --raw-output '.platforms' meta.json)
    mainProgram=$(jq --raw-output '.mainProgram' meta.json)

    echo "description: $description"
    echo "available: $available"
    echo "platforms: $platforms"
    echo "mainProgram: $mainProgram"

    if [ "$description" == "null" ]; then
      echo "error: meta.description not set" >&2
      exit 1
    fi

    if [ "$available" != "true" ]; then
      echo "error: meta.available not true" >&2
      exit 1
    fi

    if [ -d "$checkPkg/bin" ]; then
      bins=$(find $checkPkg/bin/ -type f)
      if [ -n "$bins" ] && [ "$mainProgram" = "null" ]; then
        echo "error: found $bins, but meta.mainProgram is not set" >&2
        exit 1
      fi
    fi

    touch $out
  ''
