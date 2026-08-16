#!/usr/bin/env bash
# Where each component declares its version, and which paths oblige it to move.
# Both workflows ask this script rather than repeating the answer.
#
#   component.sh version api        -> version in the working tree
#   component.sh version api <ref>  -> version at that git ref
#   component.sh watch api          -> paths whose change requires a bump
set -euo pipefail

mode=$1
component=$2
ref=${3:-}

case "$component" in
  api)      manifest=api/Cargo.toml;        watch="api" ;;
  frontend) manifest=frontend/package.json; watch="frontend" ;;
  # apps.yaml is watched but does not hold the version: infra/app reads it at
  # apply time, so changing it changes what the terraform does. When infra and
  # apps split into separate repositories that path simply drops out.
  base)     manifest=infra/VERSION;         watch="infra apps.yaml" ;;
  *)        echo "unknown component: $component" >&2; exit 1 ;;
esac

case "$mode" in
  watch)
    echo "$watch"
    ;;
  version)
    if [ -n "$ref" ]; then
      content=$(git show "$ref:$manifest")
    else
      content=$(cat "$manifest")
    fi
    case "$component" in
      api)      sed -n 's/^version = "\(.*\)"/\1/p' <<<"$content" | head -1 ;;
      frontend) node -p "JSON.parse(require('fs').readFileSync(0,'utf8')).version" <<<"$content" ;;
      base)     echo "$content" ;;
    esac
    ;;
  *)
    echo "unknown mode: $mode" >&2
    exit 1
    ;;
esac
