# Launch Buttons

Launch buttons are configured executable entry points stored in the `launch` array of history records. Use the `{installDirectory}` macro for paths relative to the install root.

## LaunchObject Schema

| Field | Description |
|---|---|
| `name` | Display name for the button |
| `executable` | Path to executable. Use `{installDirectory}` macro for paths relative to install root. |
| `arguments` | Command-line arguments to pass |

## View Launch Buttons

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE/history?product=$PRODUCT&env=$ENV&limit=1&sortDirection=backward" \
  | jq '.items[0].launch'
```

## Add a Launch Button

Get the latest history, append to the `launch` array, and PUT as a new history record:

```bash
LATEST=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE/history?product=$PRODUCT&env=$ENV&limit=1&sortDirection=backward" \
  | jq '.items[0]')

echo "$LATEST" | jq '{
  product: .product, env: .env,
  history: "'$(uuidgen | tr A-Z a-z)'",
  createdTime: '$(date +%s)',
  snapshot: .snapshot,
  launch: [(.launch // [])[], {
    name: "BUTTON_NAME",
    executable: "{installDirectory}/path/to/executable",
    arguments: ""
  }]
}' | curl -s -X PUT -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" "$BASE/history" -d @- | jq .
```

## Remove a Launch Button

Same approach — filter out the button by name:

```bash
LATEST=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE/history?product=$PRODUCT&env=$ENV&limit=1&sortDirection=backward" \
  | jq '.items[0]')

echo "$LATEST" | jq '{
  product: .product, env: .env,
  history: "'$(uuidgen | tr A-Z a-z)'",
  createdTime: '$(date +%s)',
  snapshot: .snapshot,
  launch: [(.launch // [])[] | select(.name != "BUTTON_NAME")]
}' | curl -s -X PUT -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" "$BASE/history" -d @- | jq .
```

## Launching via CLI

The environment must be installed locally first (`solsta_cli local install`). Then:

```bash
solsta_cli local launch --launch_name="BUTTON_NAME" \
  --location="/absolute/path/to/install/" --stage=$STAGE --out=json,minify
```

Note: The `--location` must be a fully resolved absolute path — the CLI does not expand `~` or environment variables.
