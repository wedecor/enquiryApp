#!/usr/bin/env bash

set -euo pipefail

WORKFLOW_ID="${1:-}"

if [[ -z "$WORKFLOW_ID" ]]; then
  gh run list --limit 10 --json databaseId,headBranch,status,conclusion,displayTitle |
    jq -r '.[0].databaseId' |
    xargs -I{} gh run view {} --log
else
  gh run view "$WORKFLOW_ID" --log
fi

