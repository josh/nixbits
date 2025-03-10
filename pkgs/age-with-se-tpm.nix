{
  symlinkJoin,
  makeWrapper,
  age,
  age-plugin-tpm,
  nur,
}:
let
  inherit (nur.repos.josh) age-plugin-se;
in
symlinkJoin {
  pname = "age-with-se-tpm";
  inherit (age) version;
  paths = [
    age
    age-plugin-se
    age-plugin-tpm
  ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    rm $out/bin/age
    makeWrapper ${age}/bin/age $out/bin/age \
      --prefix PATH : "${age-plugin-se}/bin:${age-plugin-tpm}/bin"
  '';

  meta = {
    inherit (age.meta)
      changelog
      description
      homepage
      license
      ;
    inherit (age-plugin-se.meta) platforms;
    mainProgram = "age";
  };
}
