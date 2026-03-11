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

All `local` subcommands (except `read`) require `--location` as a fully resolved absolute path. Most accept `--product_id`/`--product_name` and `--env_id`/`--env_name`.

### local read

List all local installations.

```bash
solsta_cli local read --stage=dev --out=json,minify
```

### local install

Install an environment locally.

**Before installing**, always:
1. Ask the user for an install directory. Recommend `~/Games/<ProductName>/<EnvName>` or `~/Downloads/<ProductName>/<EnvName>` as defaults.
2. Run `local read` to check for existing installs of the same product/env. If found, show them to the user and ask if they want to install another copy into a different directory.

Additional flags: `--history_id`, `--history_version`, `--repository_id`, `--repository_name`, `--release_id`, `--release_version`

```bash
solsta_cli local install --product_name=<name> --env_name=<env> --location=<path> --stage=dev --out=json,minify
```

### local update

Update an installed environment to the latest promoted release.

Additional flag: `--all` (update every local deployment)

```bash
solsta_cli local update --product_name=<name> --env_name=<env> --location=<path> --stage=dev --out=json,minify
solsta_cli local update --all --location=<path> --stage=dev --out=json,minify
```

### local repair

Verify and repair a local installation.

Additional flag: `--all` (repair every local deployment)

```bash
solsta_cli local repair --product_name=<name> --env_name=<env> --location=<path> --stage=dev --out=json,minify
```

### local launch

Launch a configured launch button. The environment must be installed locally first. See [launch.md](launch.md) for managing launch buttons.

Additional flags: `--launch_name` (required), `--product_id`/`--product_name`, `--env_id`/`--env_name`

```bash
solsta_cli local launch --launch_name=<name> --location=<path> --stage=dev --out=json,minify
```

### local uninstall

Uninstall a local environment. This is local-only and does **not** go through the orchestration queue.

Additional flag: `--all` (uninstall every local deployment)

```bash
solsta_cli local uninstall --product_name=<name> --env_name=<env> --location=<path> --stage=dev --out=json,minify
```

### Monitoring Progress

The `install`, `update`, `repair`, and `launch` commands go through the orchestration queue and block until complete with no streaming progress output. To monitor progress in real time:

1. Run the local command in the **background** (so it doesn't block)
2. Run `scripts/queue-progress.sh <stage> [poll_interval]` in the **foreground** (so progress is visible to the user)

```bash
# Background: the local operation
solsta_cli local update --product_name=<name> --env_name=<env> \
  --location=<path> --stage=qa --out=json,minify 2>&1 | jq '.'

# Foreground (after a short delay): queue monitor
sleep 5 && bash scripts/queue-progress.sh qa 10
```

**Important:** The queue monitor must run in the foreground — running it in the background hides progress from the user. After the queue monitor exits, read the background task output for the STOP result with deployment stats.

### Result Stats

The STOP response from `install`, `update`, and `repair` includes deployment stats:

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

## Output Parsing

All commands emit JSON lines with `type`: `START`, `INFO`, `STOP`.

```bash
# Extract STOP response
grep '^{' | jq -r 'select(.type == "STOP")'

# Stream-parse mixed output
jq -Rr 'fromjson?'
```

## Agent Notes

- Always use `--sort_field=name` when listing products, environments, or repositories.
- Help commands exit with code 1 (normal, not an error).
- Successful data commands exit with code 0 and include data in the STOP line.
- Names are case-sensitive throughout the CLI.
- Timestamps in output are Unix epoch seconds.
- Repositories can be optional (`RepositoryOptional: true`).
- `NotesLocation` on releases may contain a URL (e.g. GitHub release notes) — surface this to the user.
- The CLI does not expand environment variables or `~` in paths. Bash expands `$HOME` outside double quotes and inside double quotes, but `~` only expands outside quotes. To avoid issues, always pass fully resolved absolute paths (e.g. `/Users/nathan/Downloads/...`).
