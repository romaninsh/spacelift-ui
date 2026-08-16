#!/usr/bin/env bash
# Tag a commit unless that tag is already published, so a failed release can be
# retried on the same commit.
#
#   tag.sh base-0.2.0 <sha>
set -euo pipefail

tag=$1
sha=$2

if git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1; then
  echo "$tag already exists"
  exit 0
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git tag -a "$tag" -m "$tag" "$sha"
git push origin "$tag"
