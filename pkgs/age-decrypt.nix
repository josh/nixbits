{
  runCommand,
  makeWrapper,
  nixbits,
  age,
  age-input ? nixbits.empty-file,
}:
runCommand "age-decrypt"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = age.meta // {
      mainProgram = "age-decrypt";
    };
  }
  ''
    if [ ! -f ${age-input} ]; then
      echo "error: ${age-input} not a file" >&2
      exit 1
    fi

    mkdir -p $out/bin
    makeWrapper ${age}/bin/age $out/bin/age-decrypt \
      --add-flags "--decrypt" \
      --append-flags "${age-input}"
  ''
