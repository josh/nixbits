echo "== Cluster =="
echo

kubectl api-resources --verbs=list --namespaced=false -o name | while read -r kind; do
  echo "=== $kind ==="
  echo + kubectl get --show-kind --ignore-not-found "$kind"
  kubectl get --show-kind --ignore-not-found "$kind"
  echo
done

echo
echo "== Namespaced =="
echo

kubectl api-resources --verbs=list --namespaced -o name | while read -r kind; do
  if [ "$kind" = "events" ] || [ "$kind" = "events.events.k8s.io" ]; then
    continue
  fi
  echo "=== $kind ==="
  echo + kubectl get --show-kind --ignore-not-found --all-namespaces=true "$kind"
  kubectl get --show-kind --ignore-not-found --all-namespaces=true "$kind"
  echo
done
