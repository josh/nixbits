{
  lib,
  writeShellApplication,
  age,
  coreutils,
  qrencode,
  texliveMedium,
}:
writeShellApplication {
  name = "age-keygen-paper";
  runtimeInputs = [
    age
    coreutils
    qrencode
    texliveMedium
  ];
  inheritPath = false;
  runtimeEnv = {
    TEX_TEMPLATE = "${./age-keygen-paper.tex}";
  };
  text = builtins.readFile ./age-keygen-paper.bash;
  meta.description = "Generate paper PDF of new age key";
  meta.platforms = lib.platforms.all;
}
