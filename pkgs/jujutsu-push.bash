set -o xtrace

jj git fetch --all-remotes
jj bookmark move --from "closest_bookmark(@)" --to "closest_pushable(@)"
jj git push
