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

## Looking Up Endpoints

Before making any API call, use `yq` to check the OpenAPI spec for parameter names, types, and descriptions:

```bash
# Get parameters for an endpoint
yq '.paths["/history"].get.parameters' references/manifest.swagger.yaml

# Get request body schema (for PUT/POST)
yq '.paths["/publish"].put.requestBody' references/manifest.swagger.yaml

# Look up a schema definition referenced by $ref
yq '.components.schemas.PublishObject' references/manifest.swagger.yaml

# Get response schema
yq '.paths["/product"].get.responses["200"].content["application/json"].schema' references/manifest.swagger.yaml
```

Parameter descriptions indicate the expected value type — e.g. `description: Product id` means pass the object's **ID**, not its display name. This applies to query params and request body fields alike.

## Parsing Responses

Use `jq` to parse API responses:

```bash
# Pretty print
curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/product" | jq .

# Extract specific fields
curl -s ... | jq '[.items[] | {name: .name, id: .product}]'

# Get current releases for an environment from /history
curl -s ... "/history?product=$PRODUCT_ID&env=$ENV_ID&limit=1" \
  | jq '[.items[0].snapshot[] | {repo: .repositoryName, version: .version, size: .size}]'
```

## Full Schema

Refer to [references/manifest.swagger.yaml](references/manifest.swagger.yaml) for complete request/response schemas, all query parameters, and detailed field descriptions.
