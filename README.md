# solsta-inc

Claude Code marketplace plugin for the [Solsta](https://www.solsta.io) build distribution platform.

## Installation

```
/plugin marketplace add https://github.com/snxd/solsta-claude
```

## Skills

| Skill | Description |
|-------|-------------|
| **solsta** | Solsta platform — CLI commands, REST API, products, environments, local installations, orchestration, releases, repositories, publishing, and more |

The skill includes supporting reference files for [CLI commands](skills/solsta/cli.md) and [REST API endpoints](skills/solsta/api.md) that load on demand.

## Requirements

- [Solsta CLI](https://www.solsta.io/download) (`solsta_cli`) on your PATH
- [jq](https://jqlang.github.io/jq/) — for parsing JSON API responses
- [yq](https://github.com/mikefarah/yq) — for looking up endpoints in the OpenAPI spec
