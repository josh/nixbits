{
  lib,
  writeShellApplication,
  coreutils,
  gawk,
  gnugrep,
  nixbits,
}:
writeShellApplication {
  name = "sc-auth-ssh-keygen";
  runtimeInputs = [
    coreutils
    gawk
    gnugrep
    nixbits.darwin.sc_auth
    nixbits.darwin.scutil
    nixbits.darwin.ssh-keygen
  ];
  inheritPath = false;
  runtimeEnv = {
    SSH_ASKPASS = lib.getExe' coreutils "true";
    SSH_ASKPASS_REQUIRE = "force";
    SSH_SK_PROVIDER = "/usr/lib/ssh-keychain.dylib";
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./sc-auth-ssh-keygen.bash;
  meta = {
    description = "Create a Secure Enclave SSH key and print its public key";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
}
