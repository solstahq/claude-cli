---
name: solsta-cli
description: Work with the Solsta platform CLI (solsta_cli). Use when authenticating to Solsta, reading org/product/env data, managing invites, running queue operations, managing local installations, or issuing any solsta CLI command against dev/qa/prod stages. Keywords: solsta, deploy, build distribution, game studio, environment, product, repository, release, promote, snapshot, install, update, launch, delta, CI/CD, orchestration, sync.
---

# Solsta CLI

The CLI (`solsta_cli` v7.2.191) manages products, environments, local installations, and orchestration queues. See the `solsta` skill for platform concepts, object hierarchy, and stage/host details.

## Installation

Download from https://www.solsta.io/download and place `solsta_cli` on your PATH (e.g. `/usr/local/bin/`).

Or self-update an existing install:
```bash
solsta_cli component get --name=solsta_cli --target=/usr/local/bin/
```

## Authentication

Check if the user is already logged in by running any read command (e.g. `solsta_cli org read --stage=dev`). If it fails, do interactive login:

```bash
solsta_cli login prompt \
  --org=snxd --stage=dev \
  --out=json,minify --display_token=true 2>&1
```

- CLI prints an OAuth URL — give it to the user to open in their browser
- Callback hits localhost on one of these ports (tried in order): 50121, 51803, 54012, 55053, 61020
- Always use `--display_token=true` to retrieve the access token from the STOP response
- Tokens are valid for ~12 hours

For CI/CD, use machine-to-machine credentials:
```bash
solsta_cli login client_credentials \
  --client_id=<id> --client_secret=<secret> \
  --org=snxd --stage=dev --out=json,minify --display_token=true
```

**Important:** `login` requires both `--org` and `--stage`. All other commands require only `--stage` (the CLI infers the org from the stored session).

**Important:** `solsta_cli login prompt` requires interactive terminal input — AI agents cannot perform this step. The user must log in before the AI can use other commands.

## Output Format

All commands emit JSON lines with `type`: `START`, `INFO`, `STOP`.

Parse reliably with:
```bash
grep '^{' | jq -r 'select(.type == "STOP")'
```

Or stream-parse mixed output:
```bash
jq -Rr 'fromjson?'
```

Always add `--out=json,minify` for machine-readable output.

## Common Commands

```bash
# Org info
solsta_cli org read --stage=dev --out=json,minify

# List products (use --search_query to filter)
solsta_cli product read --stage=dev --out=json,minify

# List envs for a product
solsta_cli env read --product_name=<name> --stage=dev --out=json,minify

# Read invites
solsta_cli invite read --stage=dev --out=json,minify

# Queue status
solsta_cli queue status --stage=dev --out=json,minify
```

## Common Params

- `--stage` — required on every command to identify the session
- `--org` — only required for `login`
- `--limit`, `--search_query` — filter results
- `--sort_direction` — `forward` / `backward`
- `--start_key` — pagination cursor from previous STOP response

## Install Location Convention

When installing locally, use a clear path structure: `~/Downloads/<ProductName>/<EnvName>` or `~/Games/<ProductName>`. Always ask the user for the preferred install location. The `--location` parameter is required and must be an absolute path or `~` expanded path.

## AI Agent Notes

- All CLI output uses JSON lines with `type` fields (START, INFO, STOP) when using `--out=json,minify`.
- Help commands exit with code 1 (this is normal, not an error).
- Successful data commands exit with code 0 and include data in the STOP line.
- The CLI does NOT stream progress during installs/updates — it blocks and returns results at completion. Set a generous timeout (600s) for large installs.
- Names are case-sensitive throughout the CLI.
- Timestamps in output are Unix epoch seconds.
- Repositories can be optional (`RepositoryOptional: true`) — these are components users can choose to install or skip.
- `NotesLocation` on releases may contain a URL (e.g. GitHub release notes) — surface this to the user when available.

## Full Command Reference

See `references/commands.md` for all subcommands and flags.
