{
  stdenv,
  symlinkJoin,
  makeWrapper,
  go,
  testers,
  runCommand,
}:
let
  go' = symlinkJoin {
    pname = "go";
    inherit (go) version;

    paths = [
      go
    ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/go \
        --set GOENV '/dev/null' \
        --run 'export XDG_DATA_HOME=''${XDG_DATA_HOME:-$HOME/.local/share}' \
        --run 'export GOPATH=''${XDG_DATA_HOME}/go'
      wrapProgram $out/bin/gofmt \
        --set GOENV '/dev/null' \
        --run 'export XDG_DATA_HOME=''${XDG_DATA_HOME:-$HOME/.local/share}' \
        --run 'export GOPATH=''${XDG_DATA_HOME}/go'
    '';

    meta = {
      inherit (go.meta)
        name
        description
        homepage
        platforms
        ;
      mainProgram = "go";
    };
  };
in
go'.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        go = finalAttrs.finalPackage;
        test-go-env =
          name: value:
          runCommand "test-${name}" { nativeBuildInputs = [ go ]; } ''
            export XDG_CACHE_HOME=$HOME/.cache
            export XDG_CONFIG_HOME=$HOME/.config
            export XDG_DATA_HOME=$HOME/.local/share
            expected="${value}"
            actual="$(go env ${name})"
            if [[ "$actual" != "$expected" ]]; then
              echo "expected, '$expected' but was '$actual'"
              return 1
            fi
            touch $out
          '';
      in
      {
        version = testers.testVersion {
          package = go;
          command = "go version";
          version = "go${go.version}";
        };

        go-env = test-go-env "GOENV" "/dev/null";
        go-path = test-go-env "GOPATH" "/homeless-shelter/.local/share/go";
        go-bin = test-go-env "GOBIN" "";
        go-cache = test-go-env "GOCACHE" (
          if stdenv.hostPlatform.isDarwin then
            "/homeless-shelter/Library/Caches/go-build"
          else
            "/homeless-shelter/.cache/go-build"
        );
        go-mod-cache = test-go-env "GOMODCACHE" "/homeless-shelter/.local/share/go/pkg/mod";
      };
  }
)
