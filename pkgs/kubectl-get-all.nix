{
  writeShellApplication,
  jq,
  kubectl,
}:
writeShellApplication {
  name = "kubectl-get-all";
  runtimeInputs = [
    jq
    kubectl
  ];
  inheritPath = false;
  text = builtins.readFile ./kubectl-get-all.bash;
}
