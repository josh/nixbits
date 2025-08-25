{
  writeShellApplication,
  coreutils,
}:
writeShellApplication {
  name = "new-sh";
  runtimeInputs = [ coreutils ];
  inheritPath = false;
  runtimeEnv = {
    TEMPLATE_PATH = "${./new-sh-template.bash}";
  };
  text = builtins.readFile ./new-sh.bash;
  meta.description = "Create new bash script";
}
