{
  symlinkJoin,
  makeWrapper,
  age,
  age-plugin-tpm,
}:
symlinkJoin {
  pname = "age-with-tpm";
  inherit (age) version;
  paths = [
    age
    age-plugin-tpm
  ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    rm $out/bin/age
    makeWrapper ${age}/bin/age $out/bin/age \
      --prefix PATH : "${age-plugin-tpm}/bin"
  '';

  meta = {
    inherit (age.meta)
      changelog
      description
      homepage
      license
      ;
    inherit (age-plugin-tpm.meta) platforms;
    mainProgram = "age";
  };
}
