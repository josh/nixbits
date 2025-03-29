{
  symlinkJoin,
  makeWrapper,
  age,
  nur,
}:
let
  inherit (nur.repos.josh) age-plugin-se;
in
symlinkJoin {
  pname = "age-with-se";
  inherit (age) version;
  paths = [
    age
    age-plugin-se
  ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    rm $out/bin/age $out/bin/age-keygen
    makeWrapper ${age}/bin/age $out/bin/age \
      --prefix PATH : "${age-plugin-se}/bin"
    makeWrapper ${age}/bin/age-keygen $out/bin/age-keygen \
      --prefix PATH : "${age-plugin-se}/bin"
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
