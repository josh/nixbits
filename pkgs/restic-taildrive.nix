{ restic, nixbits }:
(restic.overrideAttrs {
  pname = "restic-taildrive";
  # Disable tests requiring kvm
  passthru.tests = { };
}).override
  {
    rclone = nixbits.rclone-taildrive;
  }
