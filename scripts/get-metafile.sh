#!/bin/bash
# Fetch a release metafile from Solsta
# Usage: ./get-metafile.sh <org> <stage> <product_id> <env_id> [release_id]
#
# If release_id is omitted, fetches the latest promoted release.
# Outputs the metafile JSON (file listing with names, sizes, timestamps).

ORG="${1:?Usage: $0 <org> <stage> <product_id> <env_id> [release_id]}"
STAGE="${2:?Usage: $0 <org> <stage> <product_id> <env_id> [release_id]}"
PRODUCT="${3:?Usage: $0 <org> <stage> <product_id> <env_id> [release_id]}"
ENV="${4:?Usage: $0 <org> <stage> <product_id> <env_id> [release_id]}"
RELEASE="$5"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOKEN=$("$SCRIPT_DIR/get-token.sh" "$ORG" "$STAGE")
BASE="https://axis-${STAGE}.snxd.com"

# Get metafileLocation from environment
METAFILE_LOC=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE/manifest/env?product=$PRODUCT&env=$ENV" \
  | jq -r '.items[0].metafileLocation // .items[0].publishLocation')

if [ -z "$METAFILE_LOC" ] || [ "$METAFILE_LOC" = "null" ]; then
  echo "Error: Could not get metafileLocation for env $ENV" >&2
  exit 1
fi

# If no release specified, get latest from history
if [ -z "$RELEASE" ]; then
  RELEASE=$(curl -s -H "Authorization: Bearer $TOKEN" \
    "$BASE/manifest/history?product=$PRODUCT&env=$ENV&limit=1&sortDirection=backward" \
    | jq -r '.items[0].snapshot[0].release')
  if [ -z "$RELEASE" ] || [ "$RELEASE" = "null" ]; then
    echo "Error: No releases found in env $ENV" >&2
    exit 1
  fi
fi

# Construct metafile URL
METAFILE_URL="${METAFILE_LOC}${PRODUCT}/metafile/${RELEASE}/metafile.json"

# Get signed URL from entitlement service
SIGNED_URL=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE/entitlement/route?url=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$METAFILE_URL', safe=''))")&redirect=0" \
  | jq -r '.location')

if [ -z "$SIGNED_URL" ] || [ "$SIGNED_URL" = "null" ]; then
  echo "Error: Could not get signed URL from entitlement service" >&2
  exit 1
fi

# Download and output metafile
curl -s "$SIGNED_URL"
