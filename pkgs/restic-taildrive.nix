{ restic, nixbits }:
(restic.overrideAttrs { pname = "restic-taildrive"; }).override {
  rclone = nixbits.rclone-taildrive;
}
