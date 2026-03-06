---
name: solsta-api
description: "Solsta REST APIs for the backend gateway services. Use when making direct HTTP calls to the Solsta backend, working with Swagger/OpenAPI specs, or when the CLI doesn't cover a needed operation (e.g. releases, repositories, update paths, teams, users, publishing, history, config, entitlements, tracking). Keywords: solsta, api, swagger, rest, manifest, config, direct, entitlement, track, toolbox, orglookup, audit, release, repository, update-path, team, user, publish, history, orchestration."
---

# Solsta API

The Solsta backend exposes multiple gateway services via REST APIs. Use these when the CLI (`solsta_cli`) doesn't expose the operation you need. The Manifest API (documented below) is the primary service for release tracking and product management.

See the `solsta` skill for platform concepts, stages/hosts, and authentication. Always use CloudFront hosts (e.g. `https://axis-dev.snxd.com/`) — direct API Gateway hostnames return `401 Invalid secret`.

**OpenAPI Spec:** See `references/manifest.swagger.yaml` for the full schema.

## Making Requests

Include the Bearer token (obtained via `solsta_cli`) in all requests:
```bash
curl -H "Authorization: Bearer $TOKEN" https://axis-dev.snxd.com/<endpoint>
```

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

When more items exist beyond the current page, the response includes a `lastEvaluatedKey` object. Pass it as query parameters in the next request to fetch the next page.

```bash
# First page
curl -H "Authorization: Bearer $TOKEN" "https://axis-dev.snxd.com/product?limit=10"

# Next page — pass lastEvaluatedKey fields from previous response
curl -H "Authorization: Bearer $TOKEN" "https://axis-dev.snxd.com/product?limit=10&startKey=<lastEvaluatedKey>"
```

If `lastEvaluatedKey` is absent from the response, there are no more items. Note that fewer items than `limit` may be returned even when more pages exist (e.g. if the response exceeds 4MB or the query takes too long).

## API Notes

- Partition keys use dotted notation: `org.product`, `org.product.env`, `org.product.env.repository`
- Avoid `.` or `*` in product, environment, repository, and release IDs
- Whitespace at the beginning or ending of strings is automatically stripped
- Most properties limited to 120 characters (exceptions: locations 4096, search queries 5120)
- POST to an existing object without an optional property keeps the existing value
- POST to a non-existing object without an optional property uses the default

## Full Schema

Refer to `references/manifest.swagger.yaml` for complete request/response schemas, all query parameters, and detailed field descriptions.
