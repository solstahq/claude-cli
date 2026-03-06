---
name: solsta
description: "Solsta platform overview and skill routing. Use when the user mentions Solsta, build distribution, game deployment, or any Solsta-related task to determine which skill to use. Keywords: solsta, deploy, build, distribution, game, studio, platform."
---

# Solsta

Solsta is a fast, secure build distribution platform for game studios.

**Documentation:** https://www.solsta.io/resource-center

## Authentication

All Solsta access (CLI and API) requires a Bearer token. The only way to obtain a token is through `solsta_cli`:

```bash
# Interactive login (user must open the OAuth URL in their browser)
solsta_cli login prompt --org=snxd --stage=dev --out=json,minify --display_token=true

# Machine-to-machine (CI/CD)
solsta_cli login client_credentials --client_id=<id> --client_secret=<secret> --org=snxd --stage=dev --out=json,minify --display_token=true
```

Extract the token from the STOP response with `--display_token=true`. Tokens are valid for ~12 hours. See the `solsta-cli` skill for full auth details.

## Stages

| Stage | Host |
|-------|------|
| `dev` | axis-dev.snxd.com |
| `qa` | axis-qa.snxd.com |
| `prod` | axis.snxd.com |

## Known Env

- **Org:** `snxd` — org ID `org_4c0e2cbc973c4ed8b6fcb7b95bca9833`
- **Default stage:** `dev`

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
- **Sync** — Aligning a user's local repository with the promoted release, including download and file operations.
- **Delta Update Paths** — Byte-level differences between two releases that minimize download size. Generated automatically during deploy/promote if the environment's Update Path Count > 0.
- **Block-Level Differencing** — Monitors only modified data blocks rather than complete files. Works independently of delta settings and is always active.
- **Update Path Count** — Environment setting controlling how many prior releases get delta comparisons (0 = no deltas, 2 = two delta paths e.g. 1.0→3.0 and 2.0→3.0).
- **Storage Types** — `pieceshared` (default, shared piece storage), `piece` (dedicated piece storage), `file` (file-based storage).
- **Location** — The source storage location (bucket or CDN origin) associated with an environment.
- **Launch Buttons** — Configured executable entry points with arguments. Support `{installDirectory}` macro for subdirectory paths relative to install root.

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

- **Single Release Promotion** — Moves one repository release to a target environment. Best for independent component updates.
- **Snapshot Promotion** — Moves ALL repository releases + launch buttons atomically. Best when client + server were tested together.
- **Cross-location promotion** automatically copies files from source bucket to target bucket and creates delta update paths if target has update_path_count > 0.

### Orchestration Service

Manages concurrent installs/updates across shared networks to prevent bandwidth bottlenecks:
- Network thresholds use CIDR notation (e.g. 192.168.8.0/24)
- Device thresholds limit concurrent downloads per machine (recommended 2-4)
- Clients check in every 15 seconds; downloads auto-start when slots open
- Queue items: paused downloads exit queue; crashes clear active in 10min, pending in 24hr

### Local Caching

Studio-hosted cache server that serves content at LAN speed:
- First download populates cache; subsequent downloads served locally
- Caching starts immediately (User 1 doesn't need to finish first)
- Configured via Organization → Cache Redirects with CIDR-based IP routing
- Requires Docker, internal DNS subdomain, HTTPS certs

### Roles & Permissions

- **Organization Admin** — Creates teams, manages M2M credentials, full access
- **Team Admin** — Manages team membership, add/remove members
- **Team Member** — Access to objects their team has roles for
- Admin permissions always override Viewer permissions
- **M2M Credentials (Machines)** — Client ID + Client Secret for CI/CD automation. Machines must be assigned Viewer (install/update) or Admin (deploy) roles at Product or Environment level.

---

## Available Skills

### solsta-cli

The CLI (`solsta_cli`) is best for day-to-day operations:

- **Authentication** — login/logout
- **Products** — create, edit, delete, list
- **Environments** — create, edit, delete, list
- **Local installations** — install, update, launch, repair, uninstall
- **Invitations** — send, revoke, list
- **Orchestration queue** — status, run
- **Locations** — list valid storage locations
- **Components** — download/update CLI

### CLI Limitations

The CLI does **not** expose operations for:

- Releases (create, list, search)
- Repositories (create, list, search)
- Update paths / delta management
- Publishing / promotion
- History and snapshots
- Teams and team membership
- Users and user membership
- Machine / M2M credential management
- Environment or product member roles

For these, use the API directly.

### solsta-api

The REST API provides full access to all backend gateway services. Use it when:

- The CLI doesn't support the operation (see limitations above)
- You need fine-grained control over releases, repositories, or update paths
- You're working with teams, users, or membership management
- You need to publish or promote releases programmatically
- You want to inspect history or snapshots
- You need access to other gateway services (config, entitlement, track, toolbox, orglookup, audit)

The Manifest API Swagger spec is available in `solsta-api/references/manifest.swagger.yaml`.

## When to Use Which

| Task | Use |
|------|-----|
| Login, list products/envs | **solsta-cli** |
| Install, update, launch locally | **solsta-cli** |
| Manage invitations | **solsta-cli** |
| Orchestration queue | **solsta-cli** |
| Create/manage releases | **solsta-api** |
| Create/manage repositories | **solsta-api** |
| Publish/promote releases | **solsta-api** |
| Manage teams and users | **solsta-api** |
| View history/snapshots | **solsta-api** |
| Delta update path management | **solsta-api** |
