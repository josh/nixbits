#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

if [ "$#" -eq 0 ]; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
else
  branch=$1
fi

git config "branch.$branch.remote" origin
git config "branch.$branch.merge" "refs/heads/$branch"

echo "tracking origin/$branch" >&2
