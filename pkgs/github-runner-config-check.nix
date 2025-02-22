{
  lib,
  stdenvNoCC,
  makeWrapper,
  gh,
  github-runner,
  github-runner-url ? "https://github.com/josh/nixbits",
  github-runner-use-gh-token ? true,
}:
stdenvNoCC.mkDerivation (_finalAttrs: {
  __structuredAttrs = true;

  name = "github-runner-config-check";

  nativeBuildInputs = [ makeWrapper ];
  makeWrapperArgs =
    (lib.lists.optionals (github-runner-url != null) [
      "--add-flags"
      "--url ${github-runner-url}"
    ])
    ++ (lib.lists.optionals github-runner-use-gh-token [
      "--add-flags"
      "--pat $(${lib.getExe gh} auth token)"
    ]);

  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${github-runner}/bin/config.sh $out/bin/github-runner-config-check \
      --add-flags --check \
      "''${makeWrapperArgs[@]}"
  '';

  meta = {
    description = "Check the runner's network connectivity with GitHub server";
    platforms = lib.platforms.all;
    mainProgram = "github-runner-config-check";
  };
})
