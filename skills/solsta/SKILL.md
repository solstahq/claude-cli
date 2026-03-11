---
name: solsta
description: "Solsta build distribution platform. Use for any Solsta-related task: CLI commands, API calls, authentication, products, environments, repositories, releases, installs, promotions, orchestration, or platform concepts. Keywords: solsta, deploy, build distribution, game studio, environment, product, repository, release, promote, snapshot, install, update, launch, delta, CI/CD, orchestration, sync, api, swagger, rest, manifest."
---

# Solsta

Solsta is a fast, secure build distribution platform for game studios.

**Documentation:** https://www.solsta.io/resource-center

## Authentication

All Solsta access requires authentication. Use `scripts/get-token.sh` to login and retrieve the access token:

```bash
# Interactive login — stores token for use by other scripts and API calls
TOKEN=$(scripts/get-token.sh <org> <stage>)

# Machine-to-machine (CI/CD)
solsta_cli login client_credentials --client_id=<id> --client_secret=<secret> --org=snxd --stage=dev --out=json,minify --display_token=true
```

- `login` requires both `--org` and `--stage`. All other commands require only `--stage`.
- Tokens are valid for ~12 hours.
- `get-token.sh` runs `solsta_cli login prompt` which requires the user to open an OAuth URL in their browser.
- Never display the token in output. When capturing the token, suppress it (e.g. `TOKEN=$(scripts/get-token.sh <org> <stage>) && echo "Logged in"`).

## Stages

| Stage | Host |
|-------|------|
| `dev` | axis-dev.snxd.com |
| `qa` | axis-qa.snxd.com |
| `prod` | axis.snxd.com |

## Object Hierarchy

Solsta uses a strict hierarchy: **Organization > Product > Environment > Repository > Release**

```
Organization
└── Product (a game or project)
    └── Environment (e.g. Dev, QA, Staging, Production)
        ├── Repository (independently updatable component, e.g. game client, maps, language packs)
        │   ├── Release (a specific version, e.g. v1.0.1)
        │   │   └── Metafile (JSON manifest: file names, sizes, timestamps)
        │   └── Delta Update Paths (byte-level diffs between releases)
        ├── Snapshot (captures complete state: all repo releases + launch buttons)
        └── Launch Buttons (configured app entry points)
```

### Key Concepts

- **Product** — A collection of environments, repositories, releases, and update paths for a specific game or project.
- **Environment** — A deployable state of a Product (e.g. Dev, QA, Production). Groups repositories, each with a promoted release. Has a source location (storage bucket/CDN) and an update path count.
- **Repository** — A component of the product that can be updated independently (e.g. game client, maps, language packs, dev tools).
- **Release** — A specific version of a repository (e.g. gameClient v1.0.1). Created by deploying files.
- **Promoted Release** — The active release of a repository in an environment. This is what users sync to their machines.
- **Snapshot** — A complete, tested state of an environment: all repository releases + launch buttons. Used for atomic promotion across environments.
- **Metafile** — JSON file containing release details (file names, sizes, timestamps). Generated during deployment; used by the Solsta client for sync.
- **Delta Update Paths** — Byte-level differences between two releases that minimize download size. Generated automatically during deploy/promote if the environment's Update Path Count > 0.
- **Update Path Count** — Environment setting controlling how many prior releases get delta comparisons (0 = no deltas, 2 = two delta paths e.g. 1.0→3.0 and 2.0→3.0).
- **Storage Types** — `pieceshared` (default, shared piece storage), `piece` (dedicated piece storage), `file` (file-based storage).
- **Launch Buttons** — Configured executable entry points with arguments. Support `{installDirectory}` macro for subdirectory paths relative to install root. See [launch.md](launch.md).

### Promotion Flow

```
Deploy (CI/CD) → Dev Environment
    ↓ Promote (single release or snapshot)
QA Environment
    ↓ Promote
Staging Environment
    ↓ Promote
Production Environment → Users sync via Solsta Desktop/CLI
```

- **Single Release Promotion** — Copies the target's latest snapshot and updates one repository's release within it.
- **Snapshot Promotion** — Copies an entire source snapshot (all repos + releases) to the target environment.
- **Cross-location promotion** automatically copies files between buckets and creates delta update paths if target has update_path_count > 0.

For step-by-step promotion instructions, see [promote.md](promote.md).

### Orchestration Service

Manages concurrent installs/updates across shared networks to prevent bandwidth bottlenecks:
- Network thresholds use CIDR notation (e.g. 192.168.8.0/24)
- Device thresholds limit concurrent downloads per machine (recommended 2-4)
- Clients check in every 15 seconds; downloads auto-start when slots open

### Roles & Permissions

- **Organization Admin** — Creates teams, manages M2M credentials, full access
- **Team Admin** — Manages team membership, add/remove members
- **Team Member** — Access to objects their team has roles for
- **M2M Credentials (Machines)** — Client ID + Client Secret for CI/CD automation

---

## CLI (`solsta_cli`)

The CLI (v7.2.191) handles day-to-day operations: authentication, products, environments, local installations, invitations, orchestration queues, and locations.

### Output Format

All commands emit JSON lines with `type`: `START`, `INFO`, `STOP`. Always add `--out=json,minify` for machine-readable output.

### Common Commands

```bash
solsta_cli org read --stage=dev --out=json,minify
solsta_cli queue status --stage=dev --out=json,minify
```


### CLI Notes

- `--stage` is required on every command. `--org` is only required for `login`.
- Help commands exit with code 1 (this is normal, not an error).
- Names are case-sensitive throughout the CLI.
- The CLI does NOT stream progress during local operations — see [cli.md](cli.md) for monitoring.
- Repositories can be optional (`RepositoryOptional: true`).

For full CLI command reference, see [cli.md](cli.md).

### CLI Limitations

The CLI does **not** expose operations for: releases, repositories, update paths, publishing/promotion, history/snapshots, teams, users, machines, or member roles. For these, use the API.

---

## REST API

The Solsta backend exposes REST APIs via gateway services. Use these when the CLI doesn't support the operation you need.

Always use CloudFront hosts (e.g. `https://axis-dev.snxd.com/`) — direct API Gateway hostnames return `401`.

```bash
curl -H "Authorization: Bearer $TOKEN" https://axis-dev.snxd.com/manifest/product
```

For full API details and endpoints, see [api.md](api.md).

**Before making any API call**, use `yq` to look up the endpoint in the OpenAPI spec. Use `jq` to parse API responses.
```bash
# Look up endpoint params and schemas
yq '.paths["/history"].get.parameters' references/manifest.swagger.yaml
yq '.components.schemas.PublishObject' references/manifest.swagger.yaml

# Parse API responses
curl -s -H "Authorization: Bearer $TOKEN" "$URL" | jq .
```

---

## When to Use Which

| Task | Use |
|------|-----|
| Login | CLI |
| List products/envs/repos/releases | API (fastest) |
| Install, update, launch locally | CLI |
| Orchestration queue | CLI |
| Create/manage releases | API |
| Create/manage repositories | API |
| Publish/promote releases | API |
| Manage teams and users | API |
| View history/snapshots | API |
| Get signed URLs for content | API (entitlement service, see [api.md](api.md)) |
| Delta update path management | API |

---

## Helper Scripts

**Always prefer helper scripts over raw CLI commands when a script exists for the task.** They handle output parsing, error checking, and correct usage patterns.

| Script | Usage | Description |
|--------|-------|-------------|
| `get-token.sh` | `<org> <stage>` | Get access token via `solsta_cli login`. Used by other scripts. |
| `check-for-updates.sh` | `<org> <stage>` | Compare local installs against remote promoted releases. |
| `get-metafile.sh` | `<org> <stage> <product> <env> [release]` | Fetch a release metafile via the entitlement service. |
| `queue-progress.sh` | `<stage> [interval]` | Poll orchestration queue and display progress bars. |
