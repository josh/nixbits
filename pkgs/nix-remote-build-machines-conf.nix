{
  lib,
  stdenvNoCC,
  writeText,
  testers,
  buildMachines ? [ ],
}:
let
  listToString =
    list: if (list == null || list == [ ]) then "-" else (lib.strings.concatStringsSep "," list);
  numberToString =
    number: if (number == null || number == 0) then "-" else (builtins.toString number);
  stringToString = str: if (str == null || str == "") then "-" else str;

  # Extract from
  #   https://github.com/NixOS/nixpkgs/blob/ccb73a4/nixos/modules/config/nix-remote-build.nix
  buildMachineText =
    {
      # The hostname of the build machine
      hostName,

      # The protocol used for communicating with the build machine
      protocol ? "ssh",

      # The username to log in as on the remote host
      sshUser ? null,

      # The system type the build machine can execute derivations on
      system ? null,

      # The system types the build machine can execute derivations on
      systems ? [ ],

      # The path to the SSH private key with which to authenticate on the build machine
      sshKey ? null,

      # The number of concurrent jobs the build machine supports
      maxJobs ? 1,

      # The relative speed of this builder
      speedFactor ? 1,

      # A list of features mandatory for this builder
      mandatoryFeatures ? [ ],

      # A list of features supported by this builder
      supportedFeatures ? [ ],

      # The (base64-encoded) public host key of this builder
      publicHostKey ? null,
    }:
    assert (system == null) != (systems == [ ]);
    builtins.concatStringsSep " " [
      "${if protocol != null then "${protocol}://" else ""}${
        if sshUser != null then "${sshUser}@" else ""
      }${hostName}"
      (if systems == [ ] then (stringToString system) else (listToString systems))
      (stringToString sshKey)
      (numberToString maxJobs)
      (numberToString speedFactor)
      (listToString (supportedFeatures ++ mandatoryFeatures))
      (listToString mandatoryFeatures)
      (stringToString publicHostKey)
    ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "nix-remote-build-machines-conf";

  __structuredAttrs = true;

  inherit buildMachines;
  buildMachineLines = builtins.map buildMachineText finalAttrs.buildMachines;

  buildCommand = ''
    touch $out
    for machine in "''${buildMachineLines[@]}"; do
      echo "$machine" >>$out
    done
  '';

  passthru.tests = {
    empty = testers.testEqualContents {
      assertion = "empty";
      expected = writeText "machines" "";
      actual = finalAttrs.finalPackage.overrideAttrs { buildMachines = [ ]; };
    };

    example = testers.testEqualContents {
      assertion = "onexamplee";
      expected = writeText "machines" ''
        ssh-ng://builder x86_64-linux,aarch64-linux - 1 2 nixos-test,benchmark,big-parallel,kvm - -
      '';
      actual = finalAttrs.finalPackage.overrideAttrs {
        buildMachines = [
          {
            hostName = "builder";
            systems = [
              "x86_64-linux"
              "aarch64-linux"
            ];
            protocol = "ssh-ng";
            maxJobs = 1;
            speedFactor = 2;
            supportedFeatures = [
              "nixos-test"
              "benchmark"
              "big-parallel"
              "kvm"
            ];
            mandatoryFeatures = [ ];
          }
        ];
      };
    };
  };

  meta = {
    description = "NixOS remote build machines configuration";
    platforms = lib.platforms.all;
  };
})
