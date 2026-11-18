{
  jujutsu,
  runCommand,
  wlibEvalPackage,
  writeShellScriptBin,
  writeText,
  zsh,
}:
let
  jjConfig = writeText "prompt-jj.toml" ''
    [user]
    name = "Prompt Test"
    email = "prompt@example.org"
  '';
  probe = writeShellScriptBin "jj" ''
    test "$JJ_CONFIG" = "${jjConfig}" || exit 1
    test "$GIT_CONFIG_GLOBAL" = "$EXPECTED_GIT_CONFIG" || exit 1
    echo "$*" >>"$PROBE_LOG"
    exec ${jujutsu}/bin/jj "$@"
  '';
  decoy = writeShellScriptBin "jj" ''
    touch "$DECOY_CALLED"
    exit 1
  '';
  starship = wlibEvalPackage [
    ../../starship.nix
    {
      jujutsuWrapper = wlibEvalPackage [
        ../../jujutsu.nix
        {
          jujutsuPackage = probe // {
            inherit (jujutsu) version;
          };
          configFile.path = jjConfig;
        }
      ];
    }
  ];
in
runCommand "test-starship-jujutsu-runtime" { } ''
  export HOME="$PWD" TERM=xterm-256color JJ_CONFIG=${jjConfig}
  ${jujutsu}/bin/jj git init repo
  cd repo
  ${jujutsu}/bin/jj describe -m "Review the prompt"
  export EXPECTED_GIT_CONFIG=${starship.configuration.env.GIT_CONFIG_GLOBAL.data}
  export PROBE_LOG="$PWD/jj.log" DECOY_CALLED="$PWD/decoy-called"
  export PATH="${decoy}/bin:$PATH" JJ_CONFIG=/ignored/config
  ${starship}/bin/starship module jj_change > change
  test -s change
  test -s "$PROBE_LOG"
  : > "$PROBE_LOG"
  ${starship}/bin/starship module custom.jj_description > description
  grep -Fq "Review the prompt" description
  test -s "$PROBE_LOG"
  test ! -e "$DECOY_CALLED"
  ${starship}/bin/starship init zsh --print-full-init > init.zsh
  ${zsh}/bin/zsh -f ${./prompt-environment.zsh}
  touch "$out"
''
