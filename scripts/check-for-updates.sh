#!/bin/bash
# Compare local Solsta installs against remote promoted releases
# Usage: ./check-for-updates.sh <stage>
#
# Outputs one line per local install with update status.

STAGE="${1:-qa}"
TOKEN=$(cat /tmp/solsta_token.txt)
BASE="https://axis-${STAGE}.snxd.com/manifest"
JQ_REPOS='[.repositories[]? | "\(.repositoryName)=\(.version)"] | join(",")'
JQ_REMOTE='[.items[0].snapshot[]? | "\(.repositoryName)=\(.version)"] | join(",")'

LOCAL=$(solsta_cli local read --stage="$STAGE" --out=json,minify 2>&1 \
  | jq -r 'select(.type == "STOP") | .body.items[]')

echo "$LOCAL" \
  | jq -r '[.productName, .product, .envName, .env, ('"$JQ_REPOS"')] | @tsv' \
  | sort -u | while IFS=$'\t' read -r PROD_NAME PROD_ID ENV_NAME ENV_ID LOCAL_REPOS; do
    REMOTE=$(curl -s -H "Authorization: Bearer $TOKEN" \
      "$BASE/history?product=$PROD_ID&env=$ENV_ID&limit=1&sortDirection=backward" \
      | jq -r "$JQ_REMOTE")
    [ "$LOCAL_REPOS" = "$REMOTE" ] && STATUS="Up to date" || STATUS="Update available"
    echo "$PROD_NAME | $ENV_NAME | Local: $LOCAL_REPOS | Remote: $REMOTE | $STATUS"
  done
