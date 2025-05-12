{
  lib,
  writeShellApplication,
  coreutils,
  curl,
  diffutils,
  githubUser ? "josh",
}:
writeShellApplication {
  name = "fetch-ssh-github-authorized-keys";
  runtimeInputs = [
    coreutils
    curl
    diffutils
  ];
  inheritPath = false;
  runtimeEnv = {
    GITHUB_USER = githubUser;
  };
  text = builtins.readFile ./fetch-ssh-github-authorized-keys.bash;

  meta = {
    description = "Fetch SSH keys from GitHub profile";
    platforms = lib.platforms.all;
  };
}
