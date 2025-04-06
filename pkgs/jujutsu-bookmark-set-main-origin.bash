set -o xtrace

jj git fetch --remote origin --branch main
jj bookmark set main --revision @
jj git push --remote origin --bookmark main
