{
  lib,
  hostPlatform,
  stdenvNoCC,
  writeShellApplication,
  makeWrapper,
  coreutils,
  gh,
  nixbits,
  github-runner,
  github-runner-root ? null,
  github-runner-url ? "https://github.com/josh/nixbits",
  github-runner-use-gh-token ? true,
  github-runner-group ? null,
  github-runner-name ? null,
  github-runner-labels ? [ hostPlatform.system ],
  github-runner-ephemeral ? false,
}:
let
  github-runner-config-remove = nixbits.github-runner-config-remove.override {
    inherit github-runner-root github-runner-use-gh-token;
  };

  labels =
    if github-runner-labels != null && github-runner-labels != [ ] then
      (builtins.concatStringsSep "," github-runner-labels)
    else
      null;

  configHash = builtins.hashString "sha256" (
    builtins.toJSON {
      url = github-runner-url;
      use-gh-token = github-runner-use-gh-token;
      runnergroup = github-runner-group;
      name = github-runner-name;
      inherit labels;
      ephemeral = github-runner-ephemeral;
    }
  );
  shortConfigHash = builtins.substring 0 7 configHash;

  script = writeShellApplication {
    name = "github-runner-config";
    runtimeEnv = {
      PATH = lib.strings.makeBinPath [
        coreutils
        github-runner-config-remove
      ];
      CONFIG_HASH = configHash;
      GITHUB_RUNNER_PATH = github-runner;
    };
    text = builtins.readFile ./github-runner-config.bash;
  };
in
stdenvNoCC.mkDerivation (_finalAttrs: {
  __structuredAttrs = true;

  pname = "github-runner-config";
  version = shortConfigHash;

  nativeBuildInputs = [ makeWrapper ];
  makeWrapperArgs =
    (lib.lists.optionals (github-runner-root != null) [
      "--set"
      "RUNNER_ROOT"
      github-runner-root
    ])
    ++ [
      "--add-flags"
      "--unattended"
    ]
    ++ (lib.lists.optionals (github-runner-url != null) [
      "--add-flags"
      "--url ${github-runner-url}"
    ])
    ++ (lib.lists.optionals (github-runner-name != null) [
      "--add-flags"
      "--name ${github-runner-name}"
    ])
    ++ (lib.lists.optionals (github-runner-group != null) [
      "--add-flags"
      "--runnergroup ${github-runner-group}"
    ])
    ++ (lib.lists.optionals (labels != null) [
      "--add-flags"
      "--labels ${labels}"
    ])
    ++ [
      "--add-flags"
      "--replace"
    ]
    ++ (lib.lists.optionals github-runner-use-gh-token [
      "--add-flags"
      "--pat $(${lib.getExe gh} auth token)"
    ])
    ++ [
      "--add-flags"
      "--disableupdate"
    ]
    ++ (lib.lists.optionals github-runner-ephemeral [
      "--add-flags"
      "--ephemeral"
    ]);

  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${lib.getExe script} $out/bin/github-runner-config \
      "''${makeWrapperArgs[@]}"
  '';

  meta = {
    description = "Configure GitHub Actions runner";
    platforms = lib.platforms.all;
    mainProgram = "github-runner-config";
  };
})
