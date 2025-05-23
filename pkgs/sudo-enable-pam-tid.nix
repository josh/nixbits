{
  lib,
  writeShellApplication,
  darwin,
  coreutils,
  diffutils,
  which,
  nixbits,
}:
writeShellApplication {
  name = "sudo-enable-pam-tid";
  runtimeInputs = [
    coreutils
    darwin.sudo
    diffutils
    which
  ];
  inheritPath = false;
  runtimeEnv = {
    SUDO_LOCAL_TEMPLATE = "${./sudo_local}";
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./sudo-enable-pam-tid.bash;
  meta = {
    description = "Enable sudo authentication with Touch ID";
    platforms = lib.platforms.darwin;
  };
}
