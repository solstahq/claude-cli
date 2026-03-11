#!/bin/bash
# Get the current Solsta access token via solsta_cli login.
# Usage: TOKEN=$(./get-token.sh <org> <stage>)
#
# If no valid session exists, the user will be prompted to login in the browser.

ORG="${1:?Usage: $0 <org> <stage>}"
STAGE="${2:?Usage: $0 <org> <stage>}"

TOKEN=$(solsta_cli login prompt --org="$ORG" --stage="$STAGE" --out=json,minify --display_token=true 2>&1 \
  | jq -r 'select(.type == "STOP") | .accessToken')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "Error: Failed to get token" >&2
  exit 1
fi

echo "$TOKEN"
