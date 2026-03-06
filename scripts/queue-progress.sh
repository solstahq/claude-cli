#!/bin/bash
# Poll Solsta orchestration queue and display progress bars
# Usage: ./queue-progress.sh <stage> [poll_interval_seconds]
#
# Note: Claude Code's bash tool does not support \r carriage returns,
# so each poll prints a new line rather than updating in place.

STAGE="${1:-qa}"
INTERVAL="${2:-10}"
PREV=""

while true; do
  result=$(solsta_cli queue status --stage="$STAGE" --out=json,minify 2>&1 | python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        data = json.loads(line)
        if data.get('type') == 'STOP' and 'body' in data:
            items = data['body'].get('items', [])
            if not items:
                print('DONE')
                sys.exit(0)
            parts = []
            for item in items:
                env = item.get('envName', item.get('env', '?'))
                status = item.get('status', '?')
                progress = item.get('progress', 0)
                action = item.get('action', '?')
                bar_len = 30
                filled = int(bar_len * progress / 100)
                bar = chr(9608) * filled + chr(9617) * (bar_len - filled)
                parts.append(f'{action.upper()} {env}: [{bar}] {progress}% - {status}')
            print(' | '.join(parts))
    except:
        pass
")
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
