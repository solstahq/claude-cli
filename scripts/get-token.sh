#!/bin/bash
# Get the current Solsta access token via solsta_cli login.
# Usage: TOKEN=$(./get-token.sh <org> <stage>)
#
# Tries cached credentials first to avoid opening a browser.
# If no valid session exists, the user will be prompted to login in the browser.

ORG="${1:?Usage: $0 <org> <stage>}"
STAGE="${2:?Usage: $0 <org> <stage>}"

CRED_DIR="$HOME/Library/Application Support/Solid State Networks/Solsta"
VAULT_KEY="solsta_cli:${STAGE}:access_token"
CRED_FILE="$CRED_DIR/$(echo -n "$VAULT_KEY" | shasum -a 1 | cut -d' ' -f1).cred"

# Try to read cached token and check expiry
if [ -f "$CRED_FILE" ]; then
  CACHED_TOKEN=$(sed -n '2p' "$CRED_FILE")
  if [ -n "$CACHED_TOKEN" ]; then
    # Decode JWT payload and check exp (with 10 min padding to match CLI behavior)
    EXP=$(echo "$CACHED_TOKEN" | cut -d. -f2 | base64 -d 2>/dev/null | jq -r '.exp // 0')
    NOW=$(date +%s)
    PADDING=600
    if [ "$EXP" -gt "$((NOW + PADDING))" ] 2>/dev/null; then
      echo "$CACHED_TOKEN"
      exit 0
    fi
  fi
fi

# Cached token missing or expired — fall back to browser login
TOKEN=$(solsta_cli login prompt --org="$ORG" --stage="$STAGE" --out=json,minify --display_token=true 2>&1 \
  | jq -r 'select(.type == "STOP") | .accessToken')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "Error: Failed to get token" >&2
  exit 1
fi

echo "$TOKEN"
