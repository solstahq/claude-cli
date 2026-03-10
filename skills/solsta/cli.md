# Solsta CLI Reference

Binary: `solsta_cli` (v7.2.191)

## Global Flags

| Flag | Description |
|---|---|
| `--org=VALUE` | Org slug (e.g. `snxd`). **Required for `login` only.** |
| `--stage=VALUE` | `dev`, `qa`, or `prod`. **Required on all commands.** |
| `--out=VALUE` | Output flags: `json`, `minify` (e.g. `--out=json,minify`) |
| `--display_token=VALUE` | Include access token in response (default: false) |

## Pagination Flags (on read/status commands)

| Flag | Description |
|---|---|
| `--limit=VALUE` | Max items per request |
| `--search_query=VALUE` | Filter results |
| `--sort_direction=VALUE` | `backward` or `forward` |
| `--sort_field=VALUE` | Field to sort by (varies per command) |
| `--start_key=VALUE` | Pagination cursor from previous `lastKey` |

---

## login

| Subcommand | Description |
|---|---|
| `prompt` | Interactive browser-based OAuth login |
| `client_credentials` | Machine-to-machine login (`--client_id`, `--client_secret`) |

```bash
solsta_cli login prompt --org=snxd --stage=dev --out=json,minify --display_token=true
solsta_cli login client_credentials --client_id=<id> --client_secret=<secret> --org=snxd --stage=dev --out=json,minify --display_token=true
```

## logout

```bash
solsta_cli logout
```

---

## org

```bash
solsta_cli org read --stage=dev --out=json,minify
```

---

## product

| Subcommand | Flags |
|---|---|
| `create` | `--product_id` (required), `--product_name`, `--description` |
| `delete` | `--product_id` or `--product_name` |
| `edit` | `--product_id` or `--product_name`, `--description` |
| `read` | Pagination flags only (returns all products) |

Sort fields: `createdTime`, `modifiedTime`, `name`, `product`

```bash
solsta_cli product read --stage=dev --out=json,minify
solsta_cli product read --search_query=<query> --stage=dev --out=json,minify
solsta_cli product create --product_id=<id> --product_name=<name> --stage=dev --out=json,minify
```

---

## env

| Subcommand | Flags |
|---|---|
| `create` | `--product_id`/`--product_name`, `--env_id` (required), `--env_name`, `--description`, `--location`, `--storage_type`, `--update_path_count` |
| `delete` | `--product_id`/`--product_name`, `--env_id`/`--env_name` |
| `edit` | `--product_id`/`--product_name`, `--env_id`/`--env_name`, `--description`, `--location`, `--storage_type`, `--update_path_count` |
| `read` | `--product_id`/`--product_name` (optional), pagination flags |

Storage types: `pieceshared` (default), `piece`, `file`

Sort fields: `createdTime`, `modifiedTime`, `name`, `env`

```bash
solsta_cli env read --product_name=<name> --stage=dev --out=json,minify
solsta_cli env create --product_name=<name> --env_id=<id> --update_path_count=0 --stage=dev --out=json,minify
```

---

## invite

| Subcommand | Flags |
|---|---|
| `create` | `--invitee_email`, `--inviter_name` |
| `delete` | `--invite_id` |
| `read` | Pagination flags only |

Sort fields: `invite`, `inviteeEmail`, `inviterName`, `invitationUrl`, `createdTime`, `expireTime`

```bash
solsta_cli invite read --stage=dev --out=json,minify
solsta_cli invite create --invitee_email=<email> --inviter_name=<name> --stage=dev --out=json,minify
```

---

## queue

| Subcommand | Flags |
|---|---|
| `status` | `--device_id` (optional, defaults to current machine), pagination flags |
| `run` | (none) |

Sort fields: `createdTime`, `device`, `install`, `modifiedTime`, `networkId`, `org.createdTime`

```bash
solsta_cli queue status --stage=dev --out=json,minify
solsta_cli queue run --stage=dev --out=json,minify
```

---

## location

```bash
solsta_cli location read --stage=dev --out=json,minify
```

---

## component

| Subcommand | Flags |
|---|---|
| `get` | `--name` (default: `solsta_cli`), `--platform`, `--target` (default: cwd), `--version` (default: 7.2.191) |

```bash
solsta_cli component get --name=solsta_cli --target=/usr/local/bin/ --out=json,minify
```

---

## local

| Subcommand | Description |
|---|---|
| `install` | Install a local environment |
| `update` | Update a local environment |
| `launch` | Launch an application |
| `repair` | Repair a local environment |
| `uninstall` | Uninstall a local environment |
| `read` | List local environments |

All subcommands (except `read`) require `--location`. Most accept `--product_id`/`--product_name` and `--env_id`/`--env_name`.

`install` additional flags: `--history_id`, `--history_version`, `--repository_id`, `--repository_name`, `--release_id`, `--release_version`

`launch` additional flags: `--launch_name` (required), `--product_id`/`--product_name`, `--env_id`/`--env_name`

`repair`, `uninstall`, `update` additional flag: `--all` (apply to every deployment)

```bash
solsta_cli local read --out=json,minify
solsta_cli local install --product_name=<name> --env_name=<env> --location=<path> --stage=dev --out=json,minify
solsta_cli local launch --launch_name=<name> --location=<path> --stage=dev --out=json,minify
solsta_cli local update --product_name=<name> --env_name=<env> --location=<path> --stage=dev --out=json,minify
solsta_cli local update --all --location=<path> --stage=dev --out=json,minify
solsta_cli local repair --product_name=<name> --env_name=<env> --location=<path> --stage=dev --out=json,minify
solsta_cli local uninstall --product_name=<name> --env_name=<env> --location=<path> --stage=dev --out=json,minify
```

### Checking for Updates

There is no CLI command to check for updates. Instead, compare local versions from `local read` against remote promoted versions from the `/history` API:

```bash
TOKEN=$(cat /tmp/solsta_token.txt)
LOCAL=$(solsta_cli local read --stage=$STAGE --out=json,minify 2>&1 | jq -r 'select(.type == "STOP") | .body.items[]')
echo "$LOCAL" | jq -r '[.productName, .product, .envName, .env, ([.repositories[]? | "\(.repositoryName)=\(.version)"] | join(","))] | @tsv' \
  | sort -u | while IFS=$'\t' read -r PROD_NAME PROD_ID ENV_NAME ENV_ID LOCAL_REPOS; do
    REMOTE=$(curl -s -H "Authorization: Bearer $TOKEN" \
      "$BASE/history?product=$PROD_ID&env=$ENV_ID&limit=1&sortDirection=backward" \
      | jq -r '[.items[0].snapshot[]? | "\(.repositoryName)=\(.version)"] | join(",")')
    [ "$LOCAL_REPOS" = "$REMOTE" ] && STATUS="Up to date" || STATUS="Update available"
    echo "$PROD_NAME | $ENV_NAME | Local: $LOCAL_REPOS | Remote: $REMOTE | $STATUS"
  done
```

Present results as a table with Product, Environment, Local version, Remote version, and Status columns.

### Monitoring Local Operations

The `install`, `update`, `repair`, and `launch` commands go through the orchestration queue and block until complete with no streaming progress output. To monitor progress in real time:

1. Run the local command in the background
2. Poll `solsta_cli queue status` to get the `progress` percentage and `status` field
3. A helper script is available at `scripts/queue-progress.sh <stage> [poll_interval]`

The `uninstall` command is local-only and does **not** go through the orchestration queue.

### Install Result Stats

The STOP response from `local install`/`update` includes deployment stats:

| Field | Description |
|---|---|
| `remoteReadBytes` | Bytes downloaded from remote storage |
| `localReadBytes` | Bytes read from local disk (existing data) |
| `localWriteBytes` | Bytes written to local disk |
| `remoteWriteBytes` | Bytes uploaded (tracking metadata) |
| `elapsedTime` | Sync duration in seconds |
| `successful` | Boolean success indicator |
| `filesErased` | Number of files removed |

---

## Install Location Convention

When installing locally, use a clear path structure: `~/Downloads/<ProductName>/<EnvName>` or `~/Games/<ProductName>`. The `--location` parameter is required and must be an absolute path.

## Output Parsing

All commands emit JSON lines with `type`: `START`, `INFO`, `STOP`.

```bash
# Extract STOP response
grep '^{' | jq -r 'select(.type == "STOP")'

# Stream-parse mixed output
jq -Rr 'fromjson?'
```

## Agent Notes

- Help commands exit with code 1 (normal, not an error).
- Successful data commands exit with code 0 and include data in the STOP line.
- Local commands (install/update/repair/launch) block until complete — run in background and monitor via queue.
- Names are case-sensitive throughout the CLI.
- Timestamps in output are Unix epoch seconds.
- Repositories can be optional (`RepositoryOptional: true`).
- `NotesLocation` on releases may contain a URL (e.g. GitHub release notes) — surface this to the user.
