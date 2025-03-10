{
  symlinkJoin,
  makeWrapper,
  age,
  nur,
}:
let
  age-plugin-se = nur.repos.josh.age-plugin-se;
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
    rm $out/bin/age
    makeWrapper ${age}/bin/age $out/bin/age \
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
