{
  writeShellApplication,
  kubectl,
}:
writeShellApplication {
  name = "kubectl-get-all";
  runtimeInputs = [
    kubectl
  ];
  inheritPath = false;
  text = builtins.readFile ./kubectl-get-all.bash;

  meta.description = "List all resources in a Kubernetes cluster";
}
