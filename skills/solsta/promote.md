# Solsta Promotion Reference

Promotion creates a new history record on the target environment. There are two types:

- **Release Promotion** — Updates a single repository's release in the target environment's latest snapshot.
- **Snapshot Promotion** — Copies an entire snapshot (all repos, releases, and optionally launch buttons) to the target environment.

Both types use the same core API calls: ensure repos/releases exist on the target, then `PUT /manifest/history`.

Use `yq` to verify schemas before calling any endpoint:
```bash
yq '.components.schemas.HistoryObject' references/manifest.swagger.yaml
```

---

## Release Promotion

Promotes a single release by copying the target's latest history and updating one repository's release within it.

### Step 1. Get the target environment's latest history

This is the base snapshot you'll update with the new release.

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE/history?product=$PRODUCT&env=$TARGET_ENV&limit=1&sortDirection=backward" \
  | jq '.items[0]'
```

### Step 2. Get the source release info (if not already known)

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE/history?product=$PRODUCT&env=$SOURCE_ENV&limit=1&sortDirection=backward" \
  | jq '.items[0].snapshot[] | select(.repositoryName == "REPO_NAME")'
```

### Step 3. Ensure repository exists on target (PUT is idempotent)

```bash
curl -s -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$BASE/repository" -d '{
    "product": "PRODUCT_ID", "env": "TARGET_ENV_ID",
    "repository": "REPO_ID", "name": "REPO_NAME"
  }'
```

### Step 4. Ensure release exists on target

```bash
curl -s -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$BASE/release" -d '{
    "product": "PRODUCT_ID", "env": "TARGET_ENV_ID",
    "repository": "REPO_ID", "release": "RELEASE_ID", "version": "VERSION"
  }'
```

### Step 5. Create history record with updated snapshot

Take the target's latest snapshot from Step 1, replace the entry for the promoted repository with the source release info from Step 2, then PUT as a new history record.

```bash
curl -s -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$BASE/history" -d '{
    "product": "PRODUCT_ID", "env": "TARGET_ENV_ID",
    "history": "'$(uuidgen | tr A-Z a-z)'",
    "createdTime": '$(date +%s)',
    "snapshot": [
      {"repository": "REPO_ID", "release": "NEW_RELEASE_ID",
       "repositoryName": "REPO_NAME", "repositoryOptional": false,
       "version": "NEW_VERSION"},
      ... other repos unchanged from target latest history ...
    ],
    "launch": [ ... preserve from target latest history ... ]
  }'
```

Steps 3–4 can be skipped if the repo/release already exist on the target (e.g. re-promoting a previously promoted release).

---

## Snapshot Promotion

Promotes an entire history entry — all repositories, releases, and optionally launch buttons — to the target environment.

### Step 1. Get the source snapshot to promote

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE/history?product=$PRODUCT&env=$SOURCE_ENV&limit=1&sortDirection=backward" \
  | jq '.items[0]'
```

### Step 2. Get target's latest history (for launch buttons)

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE/history?product=$PRODUCT&env=$TARGET_ENV&limit=1&sortDirection=backward" \
  | jq '.items[0].launch'
```

### Step 3. Create missing repos and releases on target

For **each** entry in the source snapshot, ensure the repository and release exist on the target:

```bash
# For each snapshot entry:
curl -s -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$BASE/repository" -d '{
    "product": "PRODUCT_ID", "env": "TARGET_ENV_ID",
    "repository": "REPO_ID", "name": "REPO_NAME"
  }'

curl -s -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$BASE/release" -d '{
    "product": "PRODUCT_ID", "env": "TARGET_ENV_ID",
    "repository": "REPO_ID", "release": "RELEASE_ID", "version": "VERSION"
  }'
```

### Step 4. Create history record with the full source snapshot

```bash
curl -s -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$BASE/history" -d '{
    "product": "PRODUCT_ID", "env": "TARGET_ENV_ID",
    "history": "'$(uuidgen | tr A-Z a-z)'",
    "createdTime": '$(date +%s)',
    "snapshot": [ ... entire snapshot array from source ... ],
    "launch": [ ... from target (Step 2) or source, depending on intent ... ]
  }'
```

---

## Key Differences

| | Release Promotion | Snapshot Promotion |
|---|---|---|
| Snapshot | Copy target's latest, update one repo entry | Copy entire source snapshot |
| Launch buttons | Preserve target's | Choose: keep target's or overwrite with source's |
| Repos/releases created | Only the promoted one | All from source snapshot |
| Use case | Independent component update | Atomic multi-repo promotion |

## Rollback

A rollback is a snapshot promotion of an older history entry within the same environment. Instead of promoting from a source environment, you promote from a previous history record on the same environment.

1. List history entries to find the target snapshot:
```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE/history?product=$PRODUCT&env=$ENV&sortDirection=backward" \
  | jq '[.items[] | {history: .history, createdTime: .createdTime, snapshot: [.snapshot[] | {repo: .repositoryName, version: .version}]}]'
```

2. Follow the **Snapshot Promotion** steps above, using the older history entry as the source and the same environment as the target.

## Notes

- Default `sortDirection` is oldest-first — always use `sortDirection=backward` to get the latest history.
- PUT to `/repository` and `/release` is idempotent — safe to call even if they already exist.
- The history `createdTime` determines ordering — use current Unix timestamp.
- Cross-location promotion (different storage buckets) automatically copies files between buckets.
