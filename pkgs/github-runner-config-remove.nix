{
  lib,
  stdenvNoCC,
  makeWrapper,
  gh,
  github-runner,
  github-runner-root ? null,
  github-runner-use-gh-token ? true,
}:
stdenvNoCC.mkDerivation {
  __structuredAttrs = true;

  name = "github-runner-config-remove";

  nativeBuildInputs = [ makeWrapper ];
  makeWrapperArgs =
    [
      "--add-flags"
      "remove"
    ]
    ++ (lib.lists.optionals (github-runner-root != null) [
      "--set"
      "RUNNER_ROOT"
      github-runner-root
    ])
    ++ (lib.lists.optionals github-runner-use-gh-token [
      "--add-flags"
      "--pat $(${lib.getExe gh} auth token)"
    ]);

  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${github-runner}/bin/config.sh $out/bin/github-runner-config-remove \
      "''${makeWrapperArgs[@]}"
  '';

  meta = {
    description = "";
    platforms = lib.platforms.all;
    mainProgram = "github-runner-config-remove";
  };
}
