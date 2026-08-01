{
  lib,
  writeShellApplication,
  curl,
  jq,
}:
writeShellApplication {
  name = "argocd-auth-token-from-actions-oidc";
  runtimeInputs = [
    curl
    jq
  ];
  text = builtins.readFile ./argocd-auth-token-from-actions-oidc.bash;
  meta = {
    description = "Exchange a GitHub Actions OIDC token for an Argo CD Dex auth token";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
