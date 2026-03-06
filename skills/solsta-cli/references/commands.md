# Solsta CLI Command Reference

Binary: `solsta_cli`

## Global Flags

| Flag | Description |
|---|---|
| `--org=VALUE` | Org slug (e.g. `snxd`) |
| `--stage=VALUE` | `dev`, `qa`, or `prod` |
| `--out=VALUE` | Output flags: `json`, `minify` (e.g. `--out=json,minify`) |
| `--display_token=VALUE` | Include access token in response (default: false) |

## Pagination Flags (on read/list commands)

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
solsta_cli org read --org=snxd --stage=dev --out=json,minify
```

---

## product

| Subcommand | Flags |
|---|---|
| `create` | `--product_id` (required), `--product_name`, `--description` |
| `delete` | `--product_id` or `--product_name` |
| `edit` | `--product_id` or `--product_name`, `--description` |
| `read` | `--product_id` or `--product_name` (omit for all) |

Sort fields: `createdTime`, `modifiedTime`, `name`, `product`

```bash
solsta_cli product read --org=snxd --stage=dev --out=json,minify
solsta_cli product read --org=snxd --product_name=<name> --stage=dev --out=json,minify
```

---

## env

| Subcommand | Flags |
|---|---|
| `create` | `--env_id` (required), `--update_path_count` (required), `--product_id`/`--product_name`, `--env_name`, `--description`, `--location`, `--storage_type` |
| `delete` | `--product_id`/`--product_name`, `--env_id`/`--env_name` |
| `edit` | `--product_id`/`--product_name`, `--env_id`/`--env_name`, `--description`, `--location`, `--storage_type`, `--update_path_count` |
| `read` | `--product_id`/`--product_name` (omit for all) |

Storage types: `pieceshared` (default), `piece`, `file`

Sort fields: `createdTime`, `modifiedTime`, `name`, `env`

```bash
solsta_cli env read --org=snxd --product_name=<name> --stage=dev --out=json,minify
```

---

## invite

| Subcommand | Flags |
|---|---|
| `create` | `--invitee_email`, `--inviter_name` |
| `delete` | `--invite_id` |
| `read` | (pagination flags only) |

Sort fields: `invite`, `inviteeEmail`, `inviterName`, `invitationUrl`, `createdTime`, `expireTime`

```bash
solsta_cli invite read --org=snxd --stage=dev --out=json,minify
```

---

## queue

| Subcommand | Flags |
|---|---|
| `status` | `--device_id` (optional, defaults to current machine) |
| `run` | — |

Sort fields: `createdTime`, `device`, `install`, `modifiedTime`, `networkId`, `org.createdTime`

```bash
solsta_cli queue status --org=snxd --stage=dev --out=json,minify
```

---

## location

```bash
solsta_cli location read --out=json,minify
```

---

## component

| Flag | Description |
|---|---|
| `--name=VALUE` | Component name (default: `solsta_cli`) |
| `--platform=VALUE` | Target platform |
| `--target=VALUE` | Target file/directory (default: cwd) |
| `--version=VALUE` | Version to download |

```bash
solsta_cli component get --out=json,minify
```

---

## local

| Subcommand | Description |
|---|---|
| `install` | Install a local environment |
| `update` | Update a local environment |
| `launch` | Launch an application |
| `repair` | Repair a local environment |
| `uninstall` | Uninstall a local environment |
| `read` | List local environments |

All subcommands (except `read`) require `--location`. Most accept `--product_id`/`--product_name` and `--env_id`/`--env_name`.

`install` additional flags: `--history_id`, `--history_version`, `--repository_id`, `--repository_name`, `--release_id`, `--release_version`

`launch` additional flag: `--launch_name` (required)

`repair`, `uninstall`, `update` additional flag: `--all` (apply to every deployment)

```bash
solsta_cli local read --out=json,minify
solsta_cli local install --product_name=<name> --env_name=<env> --location=<path> --org=snxd --stage=dev --out=json,minify
solsta_cli local launch --launch_name=<name> --location=<path> --out=json,minify
solsta_cli local update --product_name=<name> --env_name=<env> --location=<path> --org=snxd --stage=dev --out=json,minify
```
