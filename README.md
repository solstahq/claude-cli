# Solsta CLI Claude Skill

Claude Code marketplace plugin for the [Solsta](https://www.solsta.io) build distribution platform.

## Installation

```
/plugin marketplace add https://github.com/solstahq/claude-cli
```

## Demo

<iframe width="560" height="315" src="https://www.youtube.com/embed/lPrAn51jbHw?si=t33fEFCL6nAXhEm4" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

## Skills

| Skill | Description |
|-------|-------------|
| **solsta** | Solsta platform — CLI commands, REST API, products, environments, local installations, orchestration, releases, repositories, publishing, and more |

The skill includes supporting reference files for [CLI commands](skills/solsta/cli.md) and [REST API endpoints](skills/solsta/api.md) that load on demand.

## Requirements

- [Solsta CLI](https://www.solsta.io/download) (`solsta_cli`) on your PATH
- [jq](https://jqlang.github.io/jq/) — for parsing JSON API responses
- [yq](https://github.com/mikefarah/yq) — for looking up endpoints in the OpenAPI spec
