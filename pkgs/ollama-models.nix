{
  lib,
  stdenvNoCC,
  fetchurl,
  lndir,
}:
let
  fetchblob =
    modelName: blob:
    let
      sha256 = lib.strings.removePrefix "sha256:" blob.digest;
      drv = fetchurl {
        name = "ollama-blob-${sha256}";
        url = "https://registry.ollama.ai/v2/library/${modelName}/blobs/sha256:${sha256}";
        inherit sha256;
      };
    in
    {
      name = sha256;
      value = drv;
    };

  fetchmodel =
    { availableModels, model }:
    let
      parts = lib.strings.splitString ":" model;
      modelName = builtins.elemAt parts 0;
      modelTag = builtins.elemAt parts 1;
      manifestPath = "${availableModels}/${modelName}/${modelTag}.json";
      manifest = builtins.fromJSON (builtins.readFile manifestPath);
      blobs = builtins.listToAttrs (
        builtins.map (fetchblob modelName) ([ manifest.config ] ++ manifest.layers)
      );
    in
    stdenvNoCC.mkDerivation {
      pname = "ollama-${modelName}";
      version = modelTag;

      __structuredAttrs = true;

      inherit
        modelName
        modelTag
        manifestPath
        blobs
        ;

      buildCommand = ''
        mkdir -p "$out/manifests/registry.ollama.ai/library/$modelName"
        cp "$manifestPath" "$out/manifests/registry.ollama.ai/library/$modelName/$modelTag"

        mkdir -p $out/blobs
        for sha256 in "''${!blobs[@]}"; do
          ln -s "''${blobs[$sha256]}" "$out/blobs/sha256-$sha256"
        done
      '';
    };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "ollama-models";

  __structuredAttrs = true;

  availableModels = "";
  models = [ ];

  ollamaModelPackages = builtins.map (
    model:
    fetchmodel {
      inherit (finalAttrs) availableModels;
      inherit model;
    }
  ) finalAttrs.models;

  nativeBuildInputs = [ lndir ];

  buildCommand = ''
    mkdir -p $out
    for p in ''${ollamaModelPackages[@]}; do
      lndir -silent $p $out
    done
  '';
})
