# Solsta REST API Reference

The Solsta backend exposes multiple gateway services via REST APIs. Use these when the CLI doesn't support the operation you need. The Manifest API is the primary service for release tracking and product management.

Always use CloudFront hosts (e.g. `https://axis-dev.snxd.com/`) — direct API Gateway hostnames return `401 Invalid secret`.

## Making Requests

Include the Bearer token (obtained via `solsta_cli login`) in all requests:

```bash
curl -H "Authorization: Bearer $TOKEN" https://axis-dev.snxd.com/manifest/<endpoint>
```

The base URL pattern is `https://{host}/manifest/` where `{host}` corresponds to the stage:

| Stage | Base URL |
|-------|----------|
| `dev` | `https://axis-dev.snxd.com/manifest/` |
| `qa` | `https://axis-qa.snxd.com/manifest/` |
| `prod` | `https://axis.snxd.com/manifest/` |

## Available Endpoints

| Endpoint | Description |
|----------|-------------|
| `/product` | Product CRUD and search |
| `/product/member` | Product team membership |
| `/env` | Environment CRUD and search |
| `/env/member` | Environment team membership |
| `/repository` | Repository CRUD and search |
| `/release` | Release CRUD and search |
| `/update-path` | Delta update path management |
| `/publish` | Publishing/promotion operations |
| `/history` | Environment history and snapshots |
| `/history/review` | History review operations |
| `/machine` | Machine/M2M credential management |
| `/machine/member` | Machine team membership |
| `/local` | Local installation tracking |
| `/orchestration/queue` | Orchestration queue management |
| `/orchestration/status` | Orchestration status |
| `/org` | Organization info |
| `/org/member` | Organization membership |
| `/team` | Team CRUD |
| `/team/member` | Team membership |
| `/user` | User management |
| `/user/member` | User team membership |
| `/me` | Current user info |

## Pagination

List endpoints support pagination via query parameters:

| Parameter | Description |
|-----------|-------------|
| `limit` | Max items per request (e.g. `?limit=10`) |
| `sortField` | Field to sort by (varies per endpoint) |
| `sortDirection` | `forward` or `backward` |
| `searchQuery` | Filter results |

When more items exist, the response includes a `lastEvaluatedKey` object. Pass it as query parameters in the next request.

```bash
# First page
curl -H "Authorization: Bearer $TOKEN" "https://axis-dev.snxd.com/manifest/product?limit=10"

# Next page
curl -H "Authorization: Bearer $TOKEN" "https://axis-dev.snxd.com/manifest/product?limit=10&startKey=<lastEvaluatedKey>"
```

If `lastEvaluatedKey` is absent, there are no more items. Fewer items than `limit` may be returned even when more pages exist (response exceeds 4MB or query takes too long).

## API Notes

- Partition keys use dotted notation: `org.product`, `org.product.env`, `org.product.env.repository`
- Avoid `.` or `*` in product, environment, repository, and release IDs
- Whitespace at the beginning or ending of strings is automatically stripped
- Most properties limited to 120 characters (exceptions: locations 4096, search queries 5120)
- POST to an existing object without an optional property keeps the existing value
- POST to a non-existing object without an optional property uses the default
- Always sort list results by name when displaying products, environments, or repositories (e.g. `?sortField=name`)

## Looking Up Endpoints

Before making any API call, use `yq` to check the OpenAPI spec for parameter names, types, and descriptions:

```bash
# Get parameters for an endpoint
yq '.paths["/history"].get.parameters' skills/solsta/references/manifest.swagger.yaml

# Get request body schema (for PUT/POST)
yq '.paths["/publish"].put.requestBody' skills/solsta/references/manifest.swagger.yaml

# Look up a schema definition referenced by $ref
yq '.components.schemas.PublishObject' skills/solsta/references/manifest.swagger.yaml

# Get response schema
yq '.paths["/product"].get.responses["200"].content["application/json"].schema' skills/solsta/references/manifest.swagger.yaml
```

Parameter descriptions indicate the expected value type — e.g. `description: Product id` means pass the object's **ID**, not its display name. This applies to query params and request body fields alike.

## Parsing Responses

Use `jq` to parse API responses:

```bash
# Pretty print
curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/product" | jq .

# Extract specific fields
curl -s ... | jq '[.items[] | {name: .name, id: .product}]'

# Get current (latest) releases for an environment from /history
# Default sort is oldest-first — use sortDirection=backward for newest
curl -s ... "/history?product=$PRODUCT_ID&env=$ENV_ID&limit=1&sortDirection=backward" \
  | jq '[.items[0].snapshot[] | {repo: .repositoryName, version: .version, size: .size}]'
```

## Entitlement Service

The entitlement service provides signed URLs for accessing protected resources (metafiles, content). It is a separate service from the Manifest API — the base path is `/entitlement/`, not `/manifest/`.

```bash
# Get a signed URL for a protected resource
curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE/entitlement/route?url=<URL>&redirect=0" | jq -r '.location'
```

- `url` — the original (unsigned) resource URL
- `redirect=0` — returns JSON with `location` field instead of redirecting
- The signed URL includes a time-limited token (e.g. `__token__=exp=...~hmac=...`)

## Fetching a Release Metafile

A metafile is a JSON manifest listing all files in a release (names, sizes, timestamps). To fetch one:

1. Get the environment's `metafileLocation` (falls back to `publishLocation`):
   ```bash
   curl -s -H "Authorization: Bearer $TOKEN" \
     "$BASE/manifest/env?product=$PRODUCT&env=$ENV" \
     | jq -r '.items[0].metafileLocation // .items[0].publishLocation'
   ```

2. Construct the metafile URL:
   ```
   {metafileLocation}{product}/metafile/{release}/metafile.json
   ```

3. Get a signed URL via the entitlement service and download:
   ```bash
   SIGNED=$(curl -s -H "Authorization: Bearer $TOKEN" \
     "$BASE/entitlement/route?url=$METAFILE_URL&redirect=0" | jq -r '.location')
   curl -s "$SIGNED" | jq '.files[] | .name'
   ```

A helper script is available at `scripts/get-metafile.sh`:
```bash
# Usage: get-metafile.sh <stage> <org> <product_id> <env_id> [release_id]
# Omit release_id to fetch the latest promoted release
scripts/get-metafile.sh ssnqa qa $PRODUCT_ID $ENV_ID | jq '[.files[] | .name]'
```

## Full Schema

Refer to [skills/solsta/references/manifest.swagger.yaml](skills/solsta/references/manifest.swagger.yaml) for complete request/response schemas, all query parameters, and detailed field descriptions.
