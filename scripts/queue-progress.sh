#!/bin/bash
# Poll Solsta orchestration queue and display progress bars
# Usage: ./queue-progress.sh <stage> [poll_interval_seconds]
#
# Note: Claude Code's bash tool does not support \r carriage returns,
# so each poll prints a new line rather than updating in place.

STAGE="${1:-qa}"
INTERVAL="${2:-10}"
PREV=""
JQ_FILTER='
  select(.type == "STOP") | .body.items // [] |
  if length == 0 then "DONE"
  else [.[] |
    ((.progress // 0) * 30 / 100 | floor) as $filled |
    "\(.action | ascii_upcase) \(.envName // .env // "?"): " +
    "[\("█" * $filled + "░" * (30 - $filled))] " +
    "\(.progress // 0)% - \(.status // "?")"
  ] | join(" | ")
  end
'

while true; do
  result=$(solsta_cli queue status --stage="$STAGE" --out=json,minify 2>&1 \
    | jq -r "$JQ_FILTER")
  if echo "$result" | grep -q "DONE"; then
    echo "Queue empty - operation complete!"
    break
  fi
  # Only print if progress changed
  if [ "$result" != "$PREV" ]; then
    echo "$result"
    PREV="$result"
  fi
  sleep "$INTERVAL"
done
