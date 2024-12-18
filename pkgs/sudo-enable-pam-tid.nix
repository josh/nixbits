{
  lib,
  writeShellScript,
  writeShellApplication,
  darwin,
  coreutils,
  diffutils,
}:
let
  install-pamd-sudo-local = writeShellScript "install-pamd-sudo-local" ''
    cat ${./sudo_local} >/etc/pam.d/sudo_local
  '';
in
writeShellApplication {
  name = "sudo-enable-pam-tid";
  runtimeInputs = [
    coreutils
    diffutils
    darwin.sudo
  ];
  text = ''
    if diff /etc/pam.d/sudo_local ${./sudo_local}; then
      echo "pam_tid already enabled" >&2
      exit 0
    fi
    echo "enabling pam_tid" >&2
    sudo ${install-pamd-sudo-local}
  '';
  meta = {
    description = "Enable sudo authentication with Touch ID";
    platforms = lib.platforms.darwin;
  };
}
